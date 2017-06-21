#!/usr/bin/env python
"""
A script to get information about the current repository that's meant to be used
as a Terraform external data source.

See https://www.terraform.io/docs/providers/external/data_source.html
"""

import argparse
import json
import logging
import re
import subprocess
import sys

MODULE = sys.modules['__main__'].__file__
LOG = logging.getLogger(MODULE)

__version__ = "0.0.1"

def run_cmd(cmd):
    """
    Run an external command with logging and debug messages.
    """
    LOG.debug("Running command: %s", cmd)
    try:
        return subprocess.check_output(cmd)
    except subprocess.CalledProcessError, exception:
        LOG.error("Command failed: %s", exception.output)
        sys.exit(1)

def get_commit():
    """
    Get current git commit from the repository this module is in.

    https://stackoverflow.com/questions/949314/how-to-retrieve-the-hash-for-the-current-commit-in-git#949391
    """
    return run_cmd(["git", "rev-parse", "HEAD"]).strip()

def get_branch():
    """
    Get current git branch from the repository this module is in.

    https://stackoverflow.com/questions/6245570/how-to-get-the-current-branch-name-in-git#12142066
    """
    return run_cmd(["git", "rev-parse", "--abbrev-ref", "HEAD"]).strip()

def get_tags():
    """
    Get all tags that reference the current commit in the repository this module
    is in.

    https://stackoverflow.com/questions/6245570/how-to-get-the-current-branch-name-in-git#12142066

    Example output of git command:
     (HEAD -> sverch/feature/deploy-version, tag: v0.0.1-pre)
    """
    ref_names_raw = run_cmd(["git", "log", "-n", "1", "--pretty=format:'%d'"])
    ref_names = re.search(".*\((.*)\).*", ref_names_raw).group(1)
    return ",".join([tag.replace("tag: ", "").strip()
                     for tag in ref_names.split(",") if "tag: " in tag])

def get_version_info():
    """
    Gets all version info as a dictionary.
    """
    return {
        "commit" : get_commit(),
        "branch" : get_branch(),
        "tags" : get_tags()
        }

def parse_command_line(argv):
    """Parse command line argument. See -h option
    :param argv: arguments on the command line must include caller file name.
    """
    formatter_class = argparse.RawDescriptionHelpFormatter
    parser = argparse.ArgumentParser(description=MODULE,
                                     formatter_class=formatter_class)
    parser.add_argument("--version", action="version",
                        version="%(prog)s {}".format(__version__))
    parser.add_argument("-v", "--verbose", dest="verbose",
                        action="store_true", help="Increases log verbosity.")
    arguments = parser.parse_args(argv[1:])
    if arguments.verbose:
        LOG.setLevel(logging.DEBUG)
    return arguments

def main():
    """Main program. Sets up logging and do some work."""
    logging.basicConfig(stream=sys.stderr, level=logging.WARN,
                        format='%(name)s (%(levelname)s): %(message)s')
    try:
        parse_command_line(sys.argv)
        print json.dumps(get_version_info())
    except KeyboardInterrupt:
        LOG.error('Program interrupted!')
    finally:
        logging.shutdown()

if __name__ == "__main__":
    sys.exit(main())
