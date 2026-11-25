# Settings import

This settings panel contains a UI to import a settings fragment and apply the settings in the fragment over your existing settings. This can be handy to, for example, copy someone else's print routing. Before the settings are applied, a pop-up shows you what the ‘overlay’ will do:

* **Changed settings**: settings that get a different value, with the old and the new value
* **Ignored settings**: settings in the fragment that this version of MomentoBooth does not use (e.g. because they were removed in a newer version), these are not applied
* **Unchanged settings**: settings in the fragment that already have the same value (collapsed by default)

A settings fragment can be supplied through dragging and dropping a `.toml` file, plain text, or browsing for a `.toml` file.

The same UI is also presented in the onboarding wizard.

## Backups

MomentoBooth makes a backup of your settings in the following cases:

* When a new version of MomentoBooth is started for the first time
* When your settings contain values that this version does not use, as these are removed the next time the settings are saved
* When your settings file cannot be read (before you choose to continue with the default settings)
* Before settings are imported or a backup is restored
* When you press *Create backup now*

The backups are listed on this page, newest first. Press *Restore…* to see what restoring a backup would change, using the same pop-up as for an import. The newest 30 backups are kept, older ones are removed automatically. *Open backup folder* shows the backup files themselves, these are plain `.toml` files, so you can also open them in a text editor or import a part of one.
