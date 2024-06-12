#!/usr/bin/env python
"""obfuscate logs - version 2024-06-12a"""

import os
import gzip
import shutil
import re
import codecs
import tarfile
from concurrent.futures import ProcessPoolExecutor
import time

# command line arguments
import argparse

ignore_paths = [
    '/td',
    '/tr',
    '/th',
    '/a',
    '/table',
    '/tbody',
    '/thead',
    '/tracez',
    '/flagz',
    '/statz',
    '/pulsez',
    '/master',
    '/head',
    '/script',
    '/font',
    '/css',
    '/javascript',
    '/html',
    '/pre',
    '/br'
    '/#',
    '/.',
    '/(',
    '/<',
    '/^',
    '/=',
    '/%%s',
    '/tmp',
    '/root',
    '/amd64'
]

match_paths = [
    '/system.slice/',
    '/user.slice/',
    '/home/cohesity',
    '/home_cohesity_data',
    '/cohesity_users_home*',
    '_Domain/',
    '/home/support/',
    '/COHESITY_YODA',
    '/cohesity_logs',
    '/healthz',
    '/sys/fs/cgroup',
    '/var/log/cohesity',
    '/var/run/ovn/',
    '/usr/bin/',
    '/bin/systemctl',
    '/status OVN',
    '/C) ,latency (us)',
    '/usr/bin',
    '/etc/ora',
    '/usr/sbin/lvs',
    '/run for volume',
    'for volume tmpfs',
    '/bin/bash',
    '/bin/lsblk',
    '/usr/sbin/',
    '/ ; USER',
    '/healthsize',
    '//www.rsyslog.com',
    '.go:',
    '/var/run/openvswitch',
    '/var/log/audit',
    '/selinux/targeted/active/modules',
    'commit_changessize: ',
    '/root ; USER',
    '/var/log/openvswitch',
    '//support.cohesity.com/',
    '/siren/v1/',
    '/pprof/heapstats from ',
    '/metrics from ',
    '/cohesity_users_home/support',
    '/threadz from ',
    '/varz from ',
    '/flagz from ',
    '/portz from ',
    '/statsz from ',
    '/tracez?component'
]

def obfuscatefile(root, filepath):
    filename = os.path.basename(filepath)
    if filename.startswith('xxx-'):
        return
    print(filepath)
    outfile = os.path.join(root, 'xxx-%s' % filename)
    with codecs.open(filepath, 'r', 'latin-1') as f_in:
        with codecs.open(outfile, 'w', 'latin-1') as f_out:
            for line in f_in:
                skipline = False
                for match_path in match_paths:
                    if match_path in line:
                        skipline = True
                        break
                if skipline is False and ('/' in line or '\\' in line):
                    tags = ''.join(re.findall(r'(<.*?[\w:|\.|-|"|=]+>)', line))
                    lineparts = re.split('=|\"|\[|\>|\<', line)
                    for linepart in lineparts:
                        windowspaths = re.findall(r'(\\.+[\w:|\.|-]+)', linepart)
                        paths = [p for p in windowspaths if p not in tags and p not in [i for i in ignore_paths]]
                        for path in paths:
                            line = line.replace(path, '\\xxx')
                        linuxpaths = re.findall(r'(\/.+[\w:|\.|-]+)', linepart)
                        paths = [p for p in linuxpaths if p not in tags and p not in [i for i in ignore_paths]]
                        for path in paths:
                            line = line.replace(path, '/xxx')
                f_out.write('%s' % line)
            f_out.close()
            f_in.close()
            os.remove(filepath)
            os.rename(outfile, filepath)

def gzfile(path):
    with open(path, 'rb') as f_in:
        with gzip.open('%s.gz' % path, 'wb') as f_out:
            shutil.copyfileobj(f_in, f_out)


def targzdirectory(path, name):
    with tarfile.open(name, "w:gz") as tarhandle:
        for root, dirs, files in os.walk(path):
            for f in files:
                fullname = os.path.join(root, f)
                relname = fullname.replace(path, '')
                tarhandle.add(os.path.join(root, f), arcname=relname)

def process_file(root, filename, parallel=True):
    filepath = os.path.join(root, filename)
    filename_short, file_extension = os.path.splitext(filename)
    if file_extension.lower() == '.gz':
        # unzip gz file
        unzippedfile = os.path.join(root, filename_short)
        with gzip.open(filepath, 'rb') as f_in:
            with open(unzippedfile, 'wb') as f_out:
                shutil.copyfileobj(f_in, f_out)
        os.remove(filepath)
        unzipped_filename_short, unzipped_file_extension = os.path.splitext(unzippedfile)
        if unzipped_file_extension.lower() == '.tar':
            # untar tar file
            untarred_folder = unzippedfile[0:-4]
            tar = tarfile.open(unzippedfile, 'r')
            tar.extractall(untarred_folder)
            tar.close()
            os.remove(unzippedfile)
            walkdir(untarred_folder, parallel=parallel, max_workers=None)
            # re-tar and re-zip
            targzdirectory(untarred_folder, filepath)
            shutil.rmtree(untarred_folder)
        else:
            obfuscatefile(root, unzippedfile)
            # re-zip
            gzfile(unzippedfile)
            os.remove(unzippedfile)
    else:
        obfuscatefile(root, filepath)

def walkdir(thispath, parallel=False, max_workers=None):
    tasks = []
    if parallel:
        with ProcessPoolExecutor(max_workers=max_workers) as executor:
            for root, dirs, files in os.walk(thispath):
                for filename in sorted(files):
                    future = executor.submit(process_file, root, filename)
                    future.add_done_callback(task_done)
                    tasks.append(future)
    else:
        for root, dirs, files in os.walk(thispath):
            for filename in sorted(files):
                process_file(root, filename, parallel=False)

def task_done(future):
    try:
        result = future.result()
    except Exception as e:
        print(f"Task generated an exception: {e}")

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('-l', '--logpath', type=str, required=True)
    parser.add_argument('-w', '--workers', type=int, default=None, help='Number of worker processes')
    parser.add_argument('-p', '--parallel', action='store_true', help='Run in parallel using ProcessPoolExecutor')
    args = parser.parse_args()
    
    logpath = args.logpath

    if os.path.isdir(logpath) is False:
        print('logpath %s is not found' % logpath)
        exit(1)
    start_time = time.time()
    walkdir(logpath, parallel=args.parallel, max_workers=args.workers)
    end_time = time.time()
    
    # Calculate and print the execution time
    execution_time = end_time - start_time
    print(f"Execution time: {execution_time} seconds")