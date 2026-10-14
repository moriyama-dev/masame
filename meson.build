project('masame',
    ['c'],
    version : '0.1.0',
    license : 'MIT',
    meson_version : '>= 0.56',
    default_options : [
        'c_std=gnu11'
    ]
)

#===============================================================================
# Project version including git commit if possible
#===============================================================================
version = meson.project_version()

if get_option('buildtype') != 'release'
    git_command = find_program('git', required : false)

    if git_command.found()
        git_commit = run_command(
            [git_command, 'rev-parse', 'HEAD'],
            check : false
        ).stdout().strip()

        if git_commit != ''
            version += ' (git-' + git_commit.substring(0, 8) + ')'
        endif
    endif
endif

#===============================================================================
# Configuration
#===============================================================================
conf_data = configuration_data()
conf_data.set('PROJECT_BUILD_DIR', meson.current_build_dir())
conf_data.set('PROJECT_SOURCE_DIR', meson.current_source_dir())
conf_data.set('PROJECT_VERSION', version)
conf_data.set('PROJECT_ASSEMBLY_VERSION', meson.project_version() + '.0')

#===============================================================================
# Compiler Settings
#===============================================================================
cc = meson.get_compiler('c')

lite_includes = []
lite_cargs = [
    '-DPCRE2_STATIC',
    '-DLITE_PROJECT_VERSION_STR="@0@"'.format(version)
]
if get_option('renderer')
    lite_cargs += '-DLITE_USE_SDL_RENDERER'
endif
if get_option('arch_tuple') != ''
    arch_tuple = get_option('arch_tuple')
else
    arch_tuple = '@0@-@1@'.format(target_machine.cpu_family(), target_machine.system())
endif
lite_cargs += '-DLITE_ARCH_TUPLE="@0@"'.format(arch_tuple)

#===============================================================================
# Linker Settings
#===============================================================================
lite_link_args = []
#===============================================================================
# Install Configuration
#===============================================================================
if get_option('portable')
    lite_bindir = '/'
    lite_docdir = '/doc'
    lite_datadir = '/data'
else
    lite_bindir = 'bin'
    lite_docdir = get_option('datadir') / 'doc' / 'masame'
    lite_datadir = get_option('datadir') / 'masame'
    install_data('resources' / 'icons' / 'masame.svg',
        install_dir : get_option('datadir') / 'icons' / 'hicolor' / 'scalable' / 'apps',
        rename : 'io.github.moriyama_dev.Masame.svg'
    )
    install_data('resources' / 'linux' / 'io.github.moriyama_dev.Masame.desktop',
        install_dir : get_option('datadir') / 'applications'
    )
    install_data('resources' / 'linux' / 'io.github.moriyama_dev.Masame.metainfo.xml',
        install_dir : get_option('datadir') / 'metainfo'
    )
endif

install_data('licenses' / 'licenses.md', install_dir : lite_docdir)

install_subdir('data' / 'core' , install_dir : lite_datadir, exclude_files : 'start.lua')
foreach data_module : ['fonts', 'plugins', 'colors']
    install_subdir(join_paths('data', data_module), install_dir : lite_datadir)
endforeach

configure_file(
    input : 'data' / 'core' / 'start.lua',
    output : 'start.lua',
    configuration : conf_data,
    install_dir : join_paths(lite_datadir, 'core'),
)

if not get_option('source-only')
    subdir('src')
endif
