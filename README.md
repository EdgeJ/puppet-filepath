
# filepath

[![Build Status](https://travis-ci.org/EdgeJ/puppet-filepath.svg?branch=master)](https://travis-ci.org/EdgeJ/puppet-filepath)

Puppet type to create and manage recursive filepaths without resorting to
needless hackery.

#### Table of Contents

1. [Description](#description)
2. [Setup - The basics of getting started with filepath](#setup)
    * [What filepath affects](#what-filepath-affects)
    * [Setup requirements](#setup-requirements)
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

And that's it! Very simple and without resorting to hacks to get the job done.

## Limitations

Not fully implemented, more to come.

## Development
In progress... :)
