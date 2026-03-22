import os
import time
import unittest

from .utils import check_pkg_exists


class TestSystem(unittest.TestCase):
    def test_os_version(self):
        # Checks that operating system is Rocky Linux
        with open('/etc/os-release', 'r', encoding='UTF-8') as fileID:
            os_release_file = {
                i.split('=')[0].strip(): i.split('=')[1].strip().strip('"')
                for i in fileID.readlines()
            }
        self.assertEqual(os_release_file['ID'], 'rocky')

    def test_time_zone(self):
        # Checks that timezone is set to `America/New_York`
        self.assertEqual(time.tzname[0], 'EST')

        tz_link = os.readlink('/etc/localtime')
        self.assertIn('America/New_York', tz_link)


class TestSystemRoot(unittest.TestCase):
    def test_root(self):
        # Checks that the script is running as root
        self.assertEqual(os.geteuid(), 0)


class TestSystemStandard(unittest.TestCase):
    def test_nonroot(self):
        # Checks that the script is not running as root
        self.assertNotEqual(os.geteuid(), 0)

    def test_sudo(self):
        # Checks for successful installation of sudo
        self.assertTrue(check_pkg_exists('sudo'))
