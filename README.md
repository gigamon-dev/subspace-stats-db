# subspace-stats-db

This is a database for storing stats about games played using the matchmaking modules included with [Subspace Server .NET](https://github.com/gigamon-dev/SubspaceServer) zone server. To view the data, the [subspace-stats-web](https://github.com/gigamon-dev/subspace-stats-web) application can be used.

The matchmaking modules included in Subspace Server .NET can be used without a database. However, even more functionality is gained when using a database. For example, the ability to balance teams based on player stats. This database is a baseline implementation designed to be used with the `SS.Matchmaking.Modules.PostgreSqlGameStats` module.

## Installation

Install [PostgreSQL](https://www.postgresql.org).

> The following instructions explain how to set up the database for Linux. For other environments it should be similar, but won't exactly match what's shown here.

### Open the `psql` terminal

Switch to the `postgres` system user account and run `psql`.

```ShellSession
$ sudo su - postgres
$ psql
```

Before we get started, it's good to know some `psql` basics:

- Each SQL statement you run ends in a semicolon, `;`. You can keep typing lines separately. It will execute when it sees the semicolon.
- If you make a typo, you can clear out the current input with **Ctrl + C**.
- The `psql` commands start with a backslash, `\`, and do not end in a semicolon.
- When done, you can quit out of the `psql` terminal by running the `\q` command.

> Note: In `pqsl`, **postgres=#** is the terminal prompt. In the following code snippets, you do not type that part.

### Create the database

In the `psql` terminal, create a new database by running the following:

```SQL
CREATE DATABASE subspacestats;
```

> You can specify a different database name if that's what you prefer.

It will look like:

```
postgres=# CREATE DATABASE subspacestats;
CREATE DATABASE
```

### Create Roles

Next, let's create roles for the database. Here are the roles we'll be creating, and their purpose.

| Role | Description |
| --- | --- |
| `ss_developer` | Group for managing permissions of developers. Owner of all the database objects. You can create a user name for yourself and make it a member of this role, rather than use the `postgres` superuser account. |
| `ss_web_server` | Group for managing permissions to the web server. |
| `ss_zone_server` | Group for managing permissions to the zone server. |

In the `psql` terminal, create the roles by running the following commands:

```SQL
CREATE ROLE ss_developer WITH
  NOLOGIN
  NOSUPERUSER
  INHERIT
  NOCREATEDB
  NOCREATEROLE
  NOREPLICATION;

CREATE ROLE ss_web_server WITH
  NOLOGIN
  NOSUPERUSER
  INHERIT
  NOCREATEDB
  NOCREATEROLE
  NOREPLICATION;

CREATE ROLE ss_zone_server WITH
  NOLOGIN
  NOSUPERUSER
  INHERIT
  NOCREATEDB
  NOCREATEROLE
  NOREPLICATION;
```

It will look like:

```
postgres=# CREATE ROLE ss_developer WITH
  NOLOGIN
  NOSUPERUSER
  INHERIT
  NOCREATEDB
  NOCREATEROLE
  NOREPLICATION;

CREATE ROLE ss_web_server WITH
  NOLOGIN
  NOSUPERUSER
  INHERIT
  NOCREATEDB
  NOCREATEROLE
  NOREPLICATION;

CREATE ROLE ss_zone_server WITH
  NOLOGIN
  NOSUPERUSER
  INHERIT
  NOCREATEDB
  NOCREATEROLE
  NOREPLICATION;
CREATE ROLE
CREATE ROLE
CREATE ROLE

```

### Create Users

Create users with the roles by running the following commands:

> These user names are for the web server and zone server to connect with. You can use different names. Just remember to use them when configuring the web app and zone server.

> **IMPORTANT: Remember to replace the passwords with your own.**

```SQL
CREATE USER webuser WITH PASSWORD 'changeme';
GRANT ss_web_server TO webuser;
CREATE USER zoneuser WITH PASSWORD 'changeme';
GRANT ss_zone_server TO zoneuser;
```

It will look like:

```
postgres=# CREATE USER webuser WITH PASSWORD 'changeme';
GRANT ss_web_server TO webuser;
CREATE USER zoneuser WITH PASSWORD 'changeme';
GRANT ss_zone_server TO zoneuser;
CREATE ROLE
GRANT
CREATE ROLE
GRANT
```

Optionally, you can create a user name for yourself and assign it the `ss_developer` role. To do that, the SQL to run will look something like:

```SQL
CREATE USER YourUserNameHere WITH PASSWORD 'changeme';
GRANT ss_developer TO YourUserNameHere;
```

We're done running commands in `psql`. Quit out with `\q`:

It will looks like:

```
postgres=# \q
```

### Load a release of subspace-stats-db into the database

In your shell, switch to the `postgres` account:

```ShellSession
$ sudo -i -u postgres
```

Download a release from [subspace-stats-db releases](https://github.com/gigamon-dev/subspace-stats-db/releases). Most likely you'll want the latest version. You can use this file to "restore" into the database you just created.

Use `curl` to download the release you want to use, replacing `<url>` with the URL of the release:

```ShellSession
$ curl -O <url>
```

Run `pg_restore` with the following command:

> Replace the file name with the one you downloaded. Also, if you chose a different database name earlier, you'll need to adjust `--dbname=` as well.

```ShellSession
$ pg_restore --dbname=subspacestats --verbose subspacestats.sql
```

### Configure PostgreSQL Client Authentication

Using the editor of your choice, edit the configuration file:
`/etc/postgresql/<version>/main/pg_hba.conf`, substituting `<version>` with the version of PostgreSQL you're using.

You'll want to configure it such that the zone server and web server can access it. The configuration will differ based on if you're running those locally or on a separate server. For how to configure it, see the documentation within the `pg_hba.conf` file itself and the [PostgreSQL documention](https://www.postgresql.org/docs/16/auth-pg-hba-conf.html).


## Configure the Subspace Server .NET matchmaking modules

These instructions are how to configure the Subspace Server .NET zone server to use the database.

1. Fill in the connection string in `conf/global.conf` using the login for the zone server that was created in an earlier step which was granted the ss_zone_server role.

```INI
[SS.Matchmaking]
DatabaseConnectionString = 
```

2. Configure `conf/Modules.config` to load the matchmaking modules. It's important that the `SS.Matchmaking.Modules.PostgreSqlGameStats` module be included as that's the part that connects to the database.

```XML
<module type="SS.Matchmaking.Modules.PlayerGroups" path="bin/modules/Matchmaking/SS.Matchmaking.dll"/>
<module type="SS.Matchmaking.Modules.MatchmakingQueues" path="bin/modules/Matchmaking/SS.Matchmaking.dll"/>
<module type="SS.Matchmaking.Modules.PostgreSqlGameStats" path="bin/modules/Matchmaking/SS.Matchmaking.dll"/>
<module type="SS.Matchmaking.Modules.OneVersusOneStats" path="bin/modules/Matchmaking/SS.Matchmaking.dll"/>
<module type="SS.Matchmaking.Modules.OneVersusOneMatch" path="bin/modules/Matchmaking/SS.Matchmaking.dll"/>
<module type="SS.Matchmaking.Modules.TeamVersusStats" path="bin/modules/Matchmaking/SS.Matchmaking.dll" />
<module type="SS.Matchmaking.Modules.TeamVersusMatch" path="bin/modules/Matchmaking/SS.Matchmaking.dll" />
```

## Configure the subspace-stats-web web app

Follow the instructions on the [subspace-stats-web repository](https://github.com/gigamon-dev/subspace-stats-web). In the connection string for the web app, use the username that was created in an earlier step which was granted the `ss_web_server` role.
