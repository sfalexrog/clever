#!/usr/bin/env python3

from github import Github
import os

API_KEY = os.environ['GITHUB_OAUTH_TOKEN']

if __name__ == '__main__':
    if len(os.sys.argv) < 4:
        print('Usage: {} <repository> <tag> <file>'.format(os.sys.argv[0]))
        exit(1)
    repo = os.sys.argv[1]
    tag = os.sys.argv[2]
    file = os.sys.argv[3]
    gh = Github(API_KEY)
    print('Finding/creating the release')
    repo = gh.get_user().get_repo(repo)
    release = repo.create_git_release(tag=tag, name=tag, message='Built {}'.format(tag))
    print('Uploading build artifacts')
    release.upload_asset(path=file, content_type='application/octet-stream')
    print('Done uploading build artifacts')
