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

    def test_device_menu_puts_alternatives_before_current(self):
        profiles = {'Laptop': (1, 2), 'Buds': (3, 4), 'Display': (5, None)}
        self.assertEqual(audio.labels_alternatives_first(profiles, 3, 4), ['Laptop', 'Display', 'Buds'])

    def test_laptop_selection_switches_hdmi_card_to_analog_duplex(self):
        graph = [{'id': 44, 'type': 'PipeWire:Interface:Device', 'info': {'props': {
            'device.api': 'alsa', 'device.bus': 'pci', 'device.name': 'alsa_card.internal'}}}]
        hdmi_nodes = ([('Built-in Audio Digital Stereo (HDMI)', 'alsa_output.internal.hdmi-stereo', 44, 51)],
                      [('Built-in Audio Analog Stereo', 'alsa_input.internal.analog-stereo', 44, 52)])
        analog_nodes = ([('Built-in Audio Analog Stereo', 'alsa_output.internal.analog-stereo', 44, 61)],
                        [('Built-in Audio Analog Stereo', 'alsa_input.internal.analog-stereo', 44, 62)])
        with patch.object(audio, 'graph_objects', return_value=graph), \
             patch.object(audio, 'bluetooth_profile_indexes', return_value={'output:analog-stereo+input:analog-stereo': 1}), \
             patch.object(audio, 'audio_nodes', side_effect=[hdmi_nodes, analog_nodes]), \
             patch.object(audio, 'run') as command:
            self.assertEqual(audio.select_laptop_audio(), (61, 62))
            self.assertEqual(command.call_args_list[0].args, ('wpctl', 'set-profile', '44', '1'))
            self.assertEqual(command.call_args_list[1].args, ('wpctl', 'set-default', '61'))
            self.assertEqual(command.call_args_list[2].args, ('wpctl', 'set-default', '62'))

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
