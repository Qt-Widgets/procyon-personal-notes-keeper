#!/usr/bin/env python

import glob
import requests
from zipfile import ZipFile, ZIP_DEFLATED
from helpers import *

navigate_to_project_dir()

version_str = get_file_text(os.path.join('release', 'version.txt'))
printc('Create redistributable package version {}'.format(version_str), Colors.BOLD)


# when run with -v, *deployqt returns 1 and prints long help message,
# so don't print stdout and don't check return code
if IS_WINDOWS:
  check_qt_path(cmd = 'windeployqt -v', print_stdout = False, check_return_code = False)
if IS_MACOS:
  check_qt_path(cmd = 'macdeployqt -v', print_stdout = False, check_return_code = False)
if IS_LINUX:
  check_qt_path()


create_dir_if_none(OUT_DIR)
os.chdir(OUT_DIR)

recreate_dir_if_exists(REDIST_DIR)

package_name = PROJECT_NAME + '-' + version_str


########################################################################
#                             Windows

def make_package_for_windows():
  os.chdir(REDIST_DIR)

  print_header('Run windeployqt...')
  execute('windeployqt ..\\..\\bin\\{} --dir . --no-translations --no-system-d3d-compiler --no-opengl-sw'.format(PROJECT_EXE))

  print_header('Clean some excessive files...')
  remove_files(['libEGL.dll', 'libGLESV2.dll'])
  remove_files(['sqldrivers\\qsqlmysql.dll',
                'sqldrivers\\qsqlodbc.dll',
                'sqldrivers\\qsqlpsql.dll'])
  remove_files(['imageformats\\qicns.dll',
                'imageformats\\qtga.dll',
                'imageformats\\qtiff.dll',
                'imageformats\\qwbmp.dll',
                'imageformats\\qwebp.dll'])

  print_header('Copy project files...')
  shutil.copyfile('..\\..\\bin\\' + PROJECT_EXE, PROJECT_EXE)

  print_header('Pack files to zip...')
  global package_name
  package_name = '{}-win-x{}.zip'.format(package_name, get_exe_bits(PROJECT_EXE))
  with ZipFile('..\\' + package_name, mode='w', compression=ZIP_DEFLATED) as z:
     for dirname, subdirs, filenames in os.walk('.'):
        for filename in filenames:
          z.write(os.path.join(dirname, filename))


########################################################################
#                           Linux

def make_package_for_linux():
  print_header('Download linuxdeployqt...')
  # Download linuxdeplyqt if none (https://github.com/probonopd/linuxdeployqt)
  # NOTE: It've broken compatibility with newer OS versions forsing to stick at Ubuntu 14 LTS.
  # See discussion here: https://github.com/probonopd/linuxdeployqt/issues/340
  # But I have nor a machine running Trusty or a wish to stick at Qt 5.5
  # (the last supported for Trusty) so have to use a more relaxed 5th version of the tool.
  linuxdeployqt = 'linuxdeployqt-5-x86_64.AppImage'
  linuxdeployqt_url = 'https://github.com/probonopd/linuxdeployqt/releases/download/5/'
  if os.path.exists(linuxdeployqt):
    print('Already there')
  else:
    r = requests.get(linuxdeployqt_url + linuxdeployqt);
    with open(linuxdeployqt, 'wb') as f: f.write(r.content)
    execute('chmod +x ' + linuxdeployqt)

  target_exe = '{}/usr/bin/{}'.format(REDIST_DIR, PROJECT_EXE)

  print_header('Create AppDir structure...')
  os.makedirs(REDIST_DIR + '/usr/bin')
  os.makedirs(REDIST_DIR + '/usr/lib')
  os.makedirs(REDIST_DIR + '/usr/share/applications')
  os.makedirs(REDIST_DIR + '/usr/share/icons/hicolor/256x256/apps')
  shutil.copyfile('../bin/{}'.format(PROJECT_EXE), target_exe)
  shutil.copyfile(
    '../release/{}.desktop'.format(PROJECT_NAME),
    '{}/usr/share/applications/{}.desktop'.format(REDIST_DIR, PROJECT_NAME))
  shutil.copyfile(
    '../img/icon/main_256.png',
    '{}/usr/share/icons/hicolor/256x256/apps/{}.png'.format(REDIST_DIR, PROJECT_NAME))

  # There will be error 'Could not determine the path to the executable' otherwise
  execute('chmod +x ' + target_exe)

  print_header('Create AppImage...')
  execute((
    './{} {}/usr/share/applications/{}.desktop ' +
    '-appimage -no-translations -no-copy-copyright-files ' +
    '-extra-plugins=iconengines,imageformats/libqsvg.so ' +
    '-exclude-libs=libqsqlmysql,libqsqlpsql,libqicns,libqico,libqtga,libqtiff,libqwbmp,libqwebp'
  ).format(linuxdeployqt, REDIST_DIR, PROJECT_NAME))

  # Seems we can't specify target AppImage name, so find it
  default_appimage_names = glob.glob(PROJECT_NAME + '-x*.AppImage')
  if len(default_appimage_names) != 1:
    print_error_and_exit('Unable to find created AppImage file')

  global package_name
  package_name = '{}-linux-x{}.AppImage'.format(package_name, get_exe_bits(target_exe))
  remove_files([package_name])
  os.rename(default_appimage_names[0], package_name)


########################################################################
#                              MacOS

def make_package_for_macos():
  os.chdir(REDIST_DIR)

  print_header('Copy application bundle...')
  remove_dir(PROJECT_EXE)
  shutil.copytree('../../bin/' + PROJECT_EXE, PROJECT_EXE)

  print_header('Run macdeployqt...')
  execute('macdeployqt {}'.format(PROJECT_EXE))

  print_header('Clean some excessive files...')
  remove_files([PROJECT_EXE + '/Contents/PlugIns/sqldrivers/libqsqlmysql.dylib',
                PROJECT_EXE + '/Contents/PlugIns/sqldrivers/libqsqlpsql.dylib'])
  remove_files([PROJECT_EXE + '/Contents/PlugIns/imageformats/libqico.dylib',
                PROJECT_EXE + '/Contents/PlugIns/imageformats/libqtga.dylib',
                PROJECT_EXE + '/Contents/PlugIns/imageformats/libqtiff.dylib',
                PROJECT_EXE + '/Contents/PlugIns/imageformats/libqwbmp.dylib',
                PROJECT_EXE + '/Contents/PlugIns/imageformats/libqwebp.dylib'])

  print_header('Pack application bundle to dmg...')
  global package_name
  package_name = package_name + '.dmg'
  remove_files(['tmp.dmg', '../' + package_name])
  execute('hdiutil create tmp.dmg -ov -volname {} -fs HFS+ -srcfolder {}'.format(PROJECT_NAME, PROJECT_EXE))
  execute('hdiutil convert tmp.dmg -format UDZO -o ../{}'.format(package_name))

########################################################################

if IS_WINDOWS:
  make_package_for_windows()
elif IS_LINUX:
  make_package_for_linux()
elif IS_MACOS:
  make_package_for_macos()

print('\nPackage created: {}'.format(package_name))
printc('Done\n', Colors.OKGREEN)
