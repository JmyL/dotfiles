import importlib.machinery
import importlib.util
import pathlib
import tempfile
import unittest
from unittest.mock import patch

loader = importlib.machinery.SourceFileLoader('audio', str(pathlib.Path.home() / '.local/bin/sway-audio-switch'))
spec = importlib.util.spec_from_loader(loader.name, loader)
audio = importlib.util.module_from_spec(spec)
loader.exec_module(audio)


class AudioSessionTests(unittest.TestCase):
    def test_capture_uses_physical_internal_source_not_autoswitch_proxy(self):
        graph = [
            {'id': 90, 'info': {'props': {'device.name': 'buds'}}},
            {'id': 75, 'info': {'props': {'device.id': 90, 'media.class': 'Audio/Source', 'bluez5.loopback': True, 'node.name': 'proxy'}}},
            {'id': 110, 'info': {'props': {'device.id': 90, 'media.class': 'Audio/Source/Internal', 'node.name': 'physical'}}},
        ]
        with patch.object(audio, 'graph_objects', return_value=graph):
            self.assertEqual(audio.physical_source('buds'), 'physical')

    def test_menu_cancel_does_not_change_profile(self):
        with patch.object(audio, 'audio_nodes', return_value=([], [])), \
             patch.object(audio, 'bluetooth_device_for_defaults', return_value=(90, {'description': 'Buds'})), \
             patch.object(audio, 'bluetooth_profile', return_value='headset-head-unit'), \
             patch.object(audio, 'pick', return_value=None) as menu, \
             patch.object(audio, 'run') as command:
            self.assertEqual(audio.toggle_bluetooth_mic_profile(), 0)
            menu.assert_called_once()
            command.assert_not_called()

    def test_existing_hfp_is_not_restored_or_reconfigured(self):
        with tempfile.TemporaryDirectory() as tmp, \
             patch.object(audio, 'capture_context', return_value={'device': 'buds', 'profile': 'headset-head-unit', 'sink': 'headphones'}), \
             patch.object(audio, 'physical_source', return_value='physical-mic'), \
             patch.object(audio, 'set_device_profile') as change:
            state = pathlib.Path(tmp) / 'state'
            self.assertEqual(audio.prepare_capture(state), 'physical-mic')
            audio.restore_capture(state)
            change.assert_not_called()

    def test_music_profile_restores_original_output(self):
        with tempfile.TemporaryDirectory() as tmp, \
             patch.object(audio, 'capture_context', return_value={'device': 'buds', 'profile': 'a2dp-sink', 'sink': 'headphones'}), \
             patch.object(audio, 'physical_source', return_value='physical-mic'), \
             patch.object(audio, 'set_device_profile') as change, \
             patch.object(audio, 'restore_sink') as output:
            state = pathlib.Path(tmp) / 'state'
            audio.prepare_capture(state)
            audio.restore_capture(state)
            self.assertEqual(change.call_args_list[0].args, ('buds', 'headset-head-unit'))
            self.assertEqual(change.call_args_list[1].args, ('buds', 'a2dp-sink'))
            output.assert_called_with('headphones')


if __name__ == '__main__':
    unittest.main()
