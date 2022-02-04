# GodotQuickSettings for Godot 3.3+
Quick settings plugin for Godot.
Easily access and edit your favorite project settings and editor settings directly from an editor dock without having to browse hundreds of properties in Project Settings window or Editor Settings.

![image](https://user-images.githubusercontent.com/3649998/152600455-9dcb230c-1637-44eb-be08-b1bfb5dcfe0e.png)

# Installation
- Copy `addons/QuickSettings` into your project (final path should be `res://addons/QuickSettings`).

![image](https://user-images.githubusercontent.com/3649998/152600575-7e666a9e-57f7-4c38-94b5-415bc62d7203.png)

- In the Godot Editor, go to **Project Settings > Plugins** and enable the **QuickSettings** plugin.

![image](https://user-images.githubusercontent.com/3649998/152600620-07f78357-3da8-4790-a12b-ae93c58a4f49.png)

By default, it will create a new tab in the right editor dock. You can drag this tab to another dock if you prefer.

# Usage
In QuickSettings dock, click on "Add Project Property" or "Add Editor Property"

![image](https://user-images.githubusercontent.com/3649998/152600702-4c61bf19-b8bd-4158-a4e6-4d6e06c73e27.png)

A property selector popups.

![image](https://user-images.githubusercontent.com/3649998/152600835-6d3b88fb-ae7f-4701-9ee4-71771fe6124b.png)

Select the property in the tree. You can filter properties by keywords.
When a property is selected, you can choose a Display Name before adding it to the dock.


After validating your choice with the **+ Add** button or by double-clicking on a property, this property will be shown in the QuickSettings dock.
You can now edit this setting directly from QuickSettings.

![image](https://user-images.githubusercontent.com/3649998/152601143-d96b94a7-8acb-4ab5-8688-d424db2fee8b.png)

Right click on a property name will show a popup menu :

![image](https://user-images.githubusercontent.com/3649998/152601268-df3715f3-fe96-4d6a-8238-995f098627f6.png)

**Copy path** will copy the property path in system clipboard (eg. application/boot_splash/bg_color)

**Copy value** will copy the Variant value (eg. Color, Vector2, Vector3, bool, int...) and allow to paste this value on another property with the same type.

**Copy value as text** will convert the value as text and copy it to the system clipboard.
It can be pasted as regular text. (eg. For Vector3 : ``(0, -1, 0)``

**Paste value** will be enabled if you previously use the **Copy value** menu on a property with the same type.

**Rename** allows to change the display value. You can customize the name to clarify the default name. (eg. Renaming ``Bg Color`` to ``Splash Color``)

![image](https://user-images.githubusercontent.com/3649998/152602285-78375079-a490-4e76-8c36-4ee6d057cd52.png)

**Move Up** and **Move Down** are used to reorder properties in the QuickSettings dock.

# Limitations and known issue

- Few properties need the editor to be restarted to take effect (eg. Changing editor language). The plugin can not restart the editor automaticaly. You'll be invited by a message to it manually.

![image](https://user-images.githubusercontent.com/3649998/152602723-7270546b-d90a-451a-b2cc-d2b0c91f93de.png)

- Very few properties are dictonaries. This type of property can not yet be added in QuickSettings dock.

# License

See [License file](./LICENSE)
