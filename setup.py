import re
import ast
import platform
from setuptools import setup, find_packages

_version_re = re.compile(r'__version__\s+=\s+(.*)')

with open('graphistry/__init__.py', 'rb') as f:
    version = str(ast.literal_eval(_version_re.search(
        f.read().decode('utf-8')).group(1)))

description = 'This is a toolkit for launching and managing a graphistry stack on your servers.'

install_requirements = [
    'click==6.7',
    'Pygments >= 2.0',  # Pygments has to be Capitalcased. WTF?
    #'prompt_toolkit>=2.0',
    'configmanager >= 1.34.0',
    'humanize >= 0.5.1',
    'cli_helpers[styles] >= 1.0.1',
    'jinja2 >= 2.10',
    'requests >= 2.18.4',
    'fabric3 >= 1.12.0',
    'docker >= 3.2.1',
]


# setproctitle is used to mask the password when running `ps` in command line.
# But this is not necessary in Windows since the password is never shown in the
# task manager. Also setproctitle is a hard dependency to install in Windows,
# so we'll only install it if we're not in Windows.
if platform.system() != 'Windows' and not platform.system().startswith("CYGWIN"):
    install_requirements.append('setproctitle >= 1.1.9')

setup(
    name='graphistry',
    author='Graphistry Core Team',
    author_email='dev@graphistry.com',
    version=version,
    license='BSD',
    url='http://graphistry.com',
    packages=find_packages(),
    include_package_data=True,
    description=description,
    package_data={'graphistry': ['private_containers','container_lists/private.txt', 'container_lists/public.txt',
                                 'bootstrap/launch.sh', 'bootstrap/make-bcrypt-contianer.sh', 'templates/httpd-config.json',
                                 'templates/pivot-config.json', 'templates/viz-app-config.json', 'requirements.txt']},
    long_description=open('README.rst').read(),
    install_requires=install_requirements,
    dependency_links=[
        "git+https://github.com/jonathanslenders/python-prompt-toolkit.git@2.0"
    ],
    entry_points='''
        [console_scripts]
        graphistry=graphistry.main:main
    ''',
    classifiers=[
        'Intended Audience :: Developers',
        'License :: OSI Approved :: BSD License',
        'Operating System :: Unix',
        'Programming Language :: Python',
        'Programming Language :: Python :: 2',
        'Programming Language :: Python :: 2.7',
        'Programming Language :: Python :: 3',
        'Programming Language :: Python :: 3.4',
        'Programming Language :: Python :: 3.5',
        'Programming Language :: Python :: 3.6',
        'Topic :: Software Development',
        'Topic :: Software Development :: Libraries :: Python Modules',
    ],
)
