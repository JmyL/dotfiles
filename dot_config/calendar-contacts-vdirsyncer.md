# vdirsyncer, khal, khard, aerc로 캘린더/연락처 연동하기

현재 메일은 `mbsync`로 동기화하고 `notmuch`로 색인한 뒤 `aerc`에서 확인한다고 가정한다. 이 문서는 같은 터미널 기반 흐름에 CalDAV/CardDAV 동기화와 조회 도구를 추가하는 절차를 정리한다.

## 목표 구조

- 메일: `mbsync` → 로컬 Maildir → `notmuch` → `aerc`
- 연락처: CardDAV 서버 → `vdirsyncer` → 로컬 vCard 저장소 → `khard` → `aerc` 주소 완성/주소록 조회
- 캘린더: CalDAV 서버 → `vdirsyncer` → 로컬 iCalendar 저장소 → `khal`/`ikhal`

## 1. 필요한 패키지 설치

```sh
# Fedora
dnf install vdirsyncer khal khard

# Ubuntu/Debian
sudo apt install vdirsyncer khal khard
```

서버 비밀번호나 앱 비밀번호는 설정 파일에 직접 쓰지 말고 `pass` 같은 비밀 저장소에서 읽도록 구성한다.

## 2. 디렉터리 준비

```sh
mkdir -p ~/.config/vdirsyncer ~/.config/khal ~/.config/khard
mkdir -p ~/.local/share/vdirsyncer/calendars ~/.local/share/vdirsyncer/contacts
```

## 3. vdirsyncer 설정

`~/.config/vdirsyncer/config`를 만든다. 아래 예시는 CalDAV와 CardDAV를 모두 동기화하는 일반 형태다. `CALDAV_URL`, `CARDDAV_URL`, 사용자명, `pass` 항목 이름은 실제 계정에 맞게 바꾼다.

```ini
[general]
status_path = "~/.local/state/vdirsyncer/status/"

[pair personal_calendar]
a = "personal_calendar_local"
b = "personal_calendar_remote"
collections = ["from a", "from b"]
metadata = ["displayname", "color"]
conflict_resolution = "b wins"

[storage personal_calendar_local]
type = "filesystem"
path = "~/.local/share/vdirsyncer/calendars/"
fileext = ".ics"

[storage personal_calendar_remote]
type = "caldav"
url = "https://CALDAV_URL/"
username = "YOUR_USERNAME"
password.fetch = ["command", "pass", "show", "mail/YOUR_ACCOUNT/app-password"]

[pair personal_contacts]
a = "personal_contacts_local"
b = "personal_contacts_remote"
collections = ["from a", "from b"]
metadata = ["displayname"]
conflict_resolution = "b wins"

[storage personal_contacts_local]
type = "filesystem"
path = "~/.local/share/vdirsyncer/contacts/"
fileext = ".vcf"

[storage personal_contacts_remote]
type = "carddav"
url = "https://CARDDAV_URL/"
username = "YOUR_USERNAME"
password.fetch = ["command", "pass", "show", "mail/YOUR_ACCOUNT/app-password"]
```

처음에는 서버의 collection 목록을 찾고 동기화한다.

```sh
vdirsyncer discover
vdirsyncer sync
```

동기화 결과는 다음처럼 확인한다.

```sh
find ~/.local/share/vdirsyncer/calendars -name '*.ics' | head
find ~/.local/share/vdirsyncer/contacts -name '*.vcf' | head
```

## 4. Google Calendar/Contacts로 설정할 때

Google 계정과 연동할 때도 기본 구조는 같지만, 현재 문서의 `CALDAV_URL`/`CARDDAV_URL` 자리에는 Google 전용 endpoint를 넣어야 한다. 일반 Google 계정 비밀번호는 쓰지 말고, 2단계 인증을 켠 뒤 생성한 앱 비밀번호를 `pass`에 저장해서 사용한다.

```sh
pass insert mail/YOUR_GMAIL/app-password
```

Google용 vdirsyncer 원격 storage 예시는 다음과 같다.

```ini
[storage google_calendar_remote]
type = "caldav"
url = "https://apidata.googleusercontent.com/caldav/v2/"
username = "YOUR_GMAIL_ADDRESS"
password.fetch = ["command", "pass", "show", "mail/YOUR_GMAIL/app-password"]

[storage google_contacts_remote]
type = "carddav"
url = "https://www.googleapis.com/carddav/v1/principals/YOUR_GMAIL_ADDRESS/lists/default/"
username = "YOUR_GMAIL_ADDRESS"
password.fetch = ["command", "pass", "show", "mail/YOUR_GMAIL/app-password"]
```

위 storage 이름을 쓰려면 pair의 원격 storage도 맞춘다.

```ini
[pair personal_calendar]
a = "personal_calendar_local"
b = "google_calendar_remote"
collections = ["from a", "from b"]
metadata = ["displayname", "color"]
conflict_resolution = "b wins"

[pair personal_contacts]
a = "personal_contacts_local"
b = "google_contacts_remote"
collections = ["from a", "from b"]
metadata = ["displayname"]
conflict_resolution = "b wins"
```

Google Calendar의 collection 디렉터리 이름은 `personal`, `default`처럼 예쁘게 나오지 않을 수 있고, 캘린더 ID나 URL-encoded 이름이 될 수 있다. `vdirsyncer discover && vdirsyncer sync` 후 실제 생성된 디렉터리를 확인해서 `khal`/`khard`의 `path`에 반영한다.

```sh
find ~/.local/share/vdirsyncer/calendars -maxdepth 2 -type d
find ~/.local/share/vdirsyncer/contacts -maxdepth 2 -type d
```

## 5. khal 설정

`~/.config/khal/config`를 만든다. `path`는 vdirsyncer가 만든 실제 캘린더 collection 디렉터리를 가리켜야 한다. 여러 캘린더가 있으면 `[calendars]` 아래에 항목을 추가한다.

```ini
[calendars]

[[personal]]
path = ~/.local/share/vdirsyncer/calendars/personal/
type = calendar
readonly = False
color = light green

[locale]
timeformat = %H:%M
dateformat = %Y-%m-%d
longdateformat = %Y-%m-%d
firstweekday = 0

[default]
default_calendar = personal
```

사용 예시는 다음과 같다.

```sh
khal list today 7d
khal calendar
ikhal
```

`khal`에서 일정을 추가/수정한 뒤에는 서버로 반영한다.

```sh
vdirsyncer sync
```

## 6. khard 설정

`aerc`가 연락처를 조회하기 쉽게 `khard`를 vCard 저장소 위에 설정한다. `~/.config/khard/khard.conf`를 만든다.

```ini
[addressbooks]
[[personal]]
path = ~/.local/share/vdirsyncer/contacts/personal/

[general]
default_action = list
editor = nvim
merge_editor = nvim -d

[contact table]
display = first_name
```

연락처 조회를 확인한다.

```sh
khard list
khard email alice
```

## 7. aerc에서 연락처 참조하기

`~/.config/aerc/aerc.conf`의 `[compose]` 또는 주소록 관련 섹션에 `khard`를 호출하는 명령을 연결한다. aerc 버전에 따라 키 이름이 다를 수 있으므로 `man aerc-config`에서 `address-book-cmd`를 확인한다.

일반적인 설정 예시는 다음과 같다.

```ini
[compose]
address-book-cmd=khard email --parsable --remove-first-line %s
```

이후 aerc 작성 화면에서 수신자 입력 중 주소 완성이 `khard` 결과를 사용한다. 동작하지 않으면 다음을 점검한다.

```sh
khard email --parsable --remove-first-line 검색어
man aerc-config | grep -n "address-book-cmd" -A3
```

## 8. 자동 동기화 설정

사용자 systemd timer로 `vdirsyncer sync`를 주기적으로 실행한다.

`~/.config/systemd/user/vdirsyncer.service`:

```ini
[Unit]
Description=Synchronize calendars and contacts with vdirsyncer

[Service]
Type=oneshot
ExecStart=/usr/bin/vdirsyncer sync
```

`~/.config/systemd/user/vdirsyncer.timer`:

```ini
[Unit]
Description=Run vdirsyncer periodically

[Timer]
OnBootSec=2m
OnUnitActiveSec=15m
Persistent=true

[Install]
WantedBy=timers.target
```

활성화한다.

```sh
systemctl --user daemon-reload
systemctl --user enable --now vdirsyncer.timer
systemctl --user list-timers vdirsyncer.timer
```

toolbox/container 안에서 작업 중이라면 사용자 systemd는 호스트 세션에서 설정하는 편이 안전하다.

## 9. 전체 점검 순서

1. `vdirsyncer discover`가 CalDAV/CardDAV collection을 찾는지 확인한다.
2. `vdirsyncer sync` 후 `~/.local/share/vdirsyncer/` 아래에 `.ics`, `.vcf` 파일이 생겼는지 확인한다.
3. `khal list today 30d`로 일정이 보이는지 확인한다.
4. `khard list`와 `khard email 검색어`로 연락처가 보이는지 확인한다.
5. `aerc` 작성 화면에서 주소 자동완성 또는 주소록 명령이 동작하는지 확인한다.
6. timer를 켠 뒤 `journalctl --user -u vdirsyncer.service`로 주기 동기화 오류가 없는지 확인한다.

## 10. 운영 팁

- 서버가 Google/Microsoft/Fastmail/Nextcloud 등이라면 일반 비밀번호 대신 앱 비밀번호 또는 전용 토큰을 사용한다.
- 양방향 편집이 필요 없으면 `khal`/`khard` 쪽 설정을 읽기 전용에 가깝게 운용하고, 충돌 정책은 서버 우선(`b wins`)으로 시작하는 것이 안전하다.
- 처음 설정할 때는 자동 timer를 켜기 전에 수동으로 `discover`와 `sync`를 몇 번 실행해 충돌이나 인증 오류를 먼저 해결한다.
- vdirsyncer collection 디렉터리 이름은 서버가 정하므로, `khal`과 `khard`의 `path`는 `find ~/.local/share/vdirsyncer -maxdepth 3 -type d`로 실제 이름을 확인한 뒤 맞춘다.
