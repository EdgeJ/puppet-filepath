
# filepath

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


## Setup

### Beginning with filepath

```puppet
filepath { '/path/to/nested/directory':
  ensure       => present,
  owner        => 'foo',
  group        => 'bar',
  mode         => '0774',
  manage_depth => 2,
}
```

## Usage

## Limitations

Not fully implemented, more to come.

## Development
In progress... :)
