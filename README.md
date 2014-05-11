git-to-wp-plugin-svn
====================

A batch script for Windows which allows you to publish easily a new version of your WordPress plugin from a Git repository.

Configuration
-------------
**Requirements**
* Git installed and accessible by the command line (Added to the PATH variable)
* SVN installed and accessible by the command line (Added to the PATH variable)

**Set up**

1. Copy the file `git-to-wp-plugin-svn.cmd` to your Git repository. It should be in the root (`my-awesome-plugin/git-to-wp-plugin-svn.cmd`)
2. Open the file in a text editor
3. Search for the following lines:
```
    ::::::::::::
    :: The configuration vars
    ::::::::::::
    ::The slug of your plugin
    set pluginslug=wp-test-plugin
    ::The file with the plugin header
    set mainfile=plugin.php
    ::Your WordPress SVN username
    set svnuser=TV productions
```
Replace `wp-test-plugin` with your plugin slug, `plugin.php` with the file of your plugin that contains
the plugin information (name, version, author) and replace `TV productions` with your WordPress SVN username.
4. Save the file. You are now good to go!

Usage
-----
When you have made your changes to your plugin and you are ready to release a new version, follow the next instructions.

**NOTE**: Make sure all the files you want to be committed to the WordPress SVN repository are under Git version control.

**Using the command line**

    $ cd my-awesome-plugin
    $ git-to-wp-plugin-svn

**Using the explorer**

Open your plugin directory and click on `git-to-wp-plugin-svn.cmd`.

Based on
--------
* [Dean Clatworthy's deploy script](https://github.com/deanc/wordpress-plugin-git-svn)
* [Brent Shepherds' modification](https://github.com/thenbrent/multisite-user-management/blob/master/deploy.sh) of Clatworthy's script