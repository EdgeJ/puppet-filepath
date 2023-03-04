
# filepath

[![Build Status](https://travis-ci.org/EdgeJ/puppet-filepath.svg?branch=master)](https://travis-ci.org/EdgeJ/puppet-filepath)
![Latest Tag](https://img.shields.io/github/tag/edgej/puppet-filepath.svg)
[![PDK Version](https://img.shields.io/puppetforge/pdk-version/edgej/filepath.svg)](https://puppet.com/docs/pdk)
[![Puppet Forge](https://img.shields.io/puppetforge/v/vStone/percona.svg)](https://forge.puppet.com/edgej/filepath)

Puppet type to create and manage recursive filepaths without resorting to
needless hackery.

#### Table of Contents

1. [Description](#description)
2. [Setup - The basics of getting started with filepath](#setup)
    * [Beginning with filepath](#beginning-with-filepath)
3. [Usage - Configuration options and additional functionality](#usage)
4. [Limitations - OS compatibility, etc.](#limitations)
5. [Development - Guide for contributing to the module](#development)

## Description

The Puppet filepath module adds the `filepath` resource that can be used
to recursively create a directory tree. 

One of the significant limitations to Puppet's `file` resource is that
it does not create parent directories, so specifying a path where the
parent directory doesn't yet exist on the filesystem will cause an error
at execution time (while typically passing any spec tests).

The `filepath` resource eliminates the common need for hacks and workarounds
to ensure that parent directories exist for a `file` resource to be created.

For example:

```puppet
exec { 'parent dir':
   command => "mkdir -p ${directory}",
   creates => $directory,
}
```

Like the built-in `file` resource, `filepath` can manage the owner, group,
and permissions of the directory. Using the `managedepth` parameter, you may
specify how many levels down to set ownership and permissions, starting from
the deepest directory.

For example, setting `/path/to/some/dir` with `managedepth => 2` will result
in the creation of the directories `path` and `to` with the default user
(root) and permissions and the directories `some` and `dir` being created with
the specified ownership and permissions.

The `filepath` resource does not manage the contents of the directory, it
only creates the directories, similar to running `mkdir -p` at the shell.

## Setup

### Beginning with filepath

No additional setup needed after installing the module. Via pluginsync, the
type will be available to all catalogs and nodes.

## Usage
A simple example:

```puppet
filepath { '/path/to/nested/directory':
  ensure      => present,
  owner       => 'foo',
  group       => 'bar',
  mode        => '0774',
  managedepth => 2,
}
```

Or, with managing a file within the nested directory tree:

```puppet
filepath { '/opt/puppetlabs/bin':
  ensure      => present,
  owner       => 'foo',
  group       => 'bar',
  mode        => '0774',
  managedepth => 2,
}

file { '/opt/puppetlabs/bin/moog':
   ensure => present,
   owner  => 'foo',
   group  => 'bar',
   mode   => '0770'.
   source => 'puppet:///modules/role/moog',
   require => Filepath['/opt/puppetlabs/bin'],
}
```

To remove a filepath, specify the path to be removed and use `managedepth` to
control how many levels of the directory tree are removed.

```sh
$ ls /path/to/
deleted

$ ls /path/to/deleted
dir
```

```puppet
filepath { '/path/to/deleted/dir':
  ensure => absent,
  managedepth => 2,
}
```

```sh
$ ls /path/to

$ ls /path/to/deleted
ls: /path/to/deleted: No such file or directory
```

And that's it! Very simple and without resorting to hacks to get the job done.

## Limitations

Currently no support for non-posix operatingsystems (that means you, Windows!)

The `filepath` resource does not manage files or contents of any directories,
only creation or deletion of the path itself. Use the built-in `file` resource
to set or remove any file or directory content.


Tested on Centos 7, Ubuntu 18.04, and Ubuntu 20.04.

## Development

The module is largely developed with the Puppet Development Kit (pdk) and can
be validated and tested with that tool. The exception is Beaker tests, which
require installation with Bundler for the gems and execution via `rake beaker`.

To submit a change to the module:

* Fork the repo.
* Make any necessary changes and validate syntax with `pdk validate`.
* Add any unit tests for any additional features.
* If applicable, add additional acceptance tests.
* Ensure all tests are passing with `pdk test unit` or `rake spec`.
* Submit a PR.
