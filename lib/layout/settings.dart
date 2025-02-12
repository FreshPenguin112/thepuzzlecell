part of layout;

String encodeColor(Color color) {
  return "${color.red}:${color.green}:${color.blue}:${color.alpha}";
}

Color decodeColor(String string) {
  final parts = string.split(":");
  return Color.fromARGB(int.parse(parts[3]), int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
}

Color settingsColor(String id, Color defaultColor) {
  final color = storage.getString(id);
  if (color == null) {
    return defaultColor;
  }
  return decodeColor(color);
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> with TickerProviderStateMixin {
  final TextEditingController _delayController = TextEditingController();
  final TextEditingController _clientIDController = TextEditingController();
  final textStyle = TextStyle(
    fontSize: 9.sp,
  );

  final textBoxStyle = TextStyle(
    fontSize: 7.sp,
  );

  Widget colorSetting(String id, String langKey, String title, Color defaultValue) {
    return Row(
      children: [
        Text(
          '${lang(langKey, title)}: ',
          style: textStyle,
        ),
        SizedBox(
          child: Button(
            child: Text(lang('choose_color', 'Choose a color'), style: textBoxStyle),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: Text(lang('choose_color', 'Choose a color')),
                    content: SingleChildScrollView(
                      child: ColorPicker(
                        pickerColor: decodeColor(storage.getString(id) ?? encodeColor(defaultValue)),
                        onColorChanged: (color) {
                          storage.setString(id, encodeColor(color)).then((v) => setState(() {}));
                        },
                      ),
                    ),
                    actions: [
                      Button(
                        child: Text('Restore to Default'),
                        onPressed: () {
                          storage.setString(id, encodeColor(defaultValue)).then((v) => setState(() {}));
                          Navigator.of(context).pop();
                        },
                      ),
                      Button(
                        child: Text('Ok'),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget checkboxSetting(String id, String langKey, String title, bool defaultValue, [void Function(bool v)? callback]) {
    return Row(
      children: [
        Text(
          '${lang(langKey, title)}: ',
          style: textStyle,
        ),
        SizedBox(
          width: 3.w,
          height: 5.h,
          child: Align(
            child: ToggleSwitch(
              checked: storage.getBool(id) ?? defaultValue,
              onChanged: (newValue) {
                storage
                    .setBool(
                      id,
                      newValue,
                    )
                    .then((e) => setState(() => callback?.call(newValue)));
              },
            ),
          ),
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();

    _delayController.text = (storage.getDouble("delay") ?? 0.15).toString();
    _clientIDController.text = storage.getString("clientID") ?? "@uuid";
    _tabController = TabController(vsync: this, length: 1);
  }

  @override
  void dispose() {
    _delayController.dispose();
    _clientIDController.dispose();
    _tabController.dispose();

    super.dispose();
  }

  late TabController _tabController;

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      header: Container(
        color: Colors.grey[100],
        child: Row(
          children: [
            Spacer(),
            Text(
              lang("settings", "Settings"),
              style: TextStyle(
                fontSize: 12.sp,
              ),
            ),
            Spacer(),
          ],
        ),
      ),
      content: DefaultTabController(
        length: 4,
        child: Scaffold(
          appBar: TabBar(
            indicatorColor: Colors.grey[100],
            isScrollable: true,
            tabs: [
              Tab(
                text: 'General',
              ),
              Tab(
                text: 'Audio',
              ),
              Tab(
                text: 'Graphics',
              ),
              Tab(
                text: 'Multiplayer',
              ),
            ],
          ),
          body: Container(
            padding: EdgeInsets.all(2.w),
            child: TabBarView(
              children: [
                ListView(
                  children: [
                    Row(
                      children: [
                        Text(
                          '${lang('update_delay', 'Update Delay')}: ',
                          style: textStyle,
                        ),
                        SizedBox(
                          width: 20.w,
                          height: 5.h,
                          child: TextBox(
                            style: textBoxStyle,
                            controller: _delayController,
                            onChanged: (str) {
                              if (num.tryParse(str) != null) {
                                storage
                                    .setDouble(
                                      "delay",
                                      max(min(num.tryParse(str)!.toDouble(), 1), 0.01),
                                    )
                                    .then(
                                      (e) => setState(
                                        () {},
                                      ),
                                    );
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    checkboxSetting(
                      'middle_move',
                      'middle_move',
                      'Middle Click Moving',
                      false,
                    ),
                    checkboxSetting(
                      'subtick',
                      'subticking',
                      'Subticking',
                      false,
                    ),
                    checkboxSetting(
                      'fullscreen',
                      'fullscreen',
                      'Fullscreen Window',
                      false,
                      (v) {
                        windowManager.setFullScreen(v);
                      },
                    ),
                    checkboxSetting(
                      'invert_zoom_scroll',
                      'invert_zoom_scroll',
                      'Invert Zoom Scrolling',
                      true,
                    ),
                    checkboxSetting(
                      'debug',
                      'debug_mode',
                      'Debug Mode',
                      false,
                    ),
                    Row(
                      children: [
                        Text(
                          lang('chunk_size', 'Chunk Size') + ': ',
                          style: textStyle,
                        ),
                        SizedBox(
                          width: 20.w,
                          height: 5.h,
                          child: Slider(
                            value: (storage.getInt("chunk_size") ?? 25).toDouble(),
                            min: 1,
                            max: 100,
                            onChanged: (v) => storage
                                .setInt(
                                  "chunk_size",
                                  v.toInt(),
                                )
                                .then(
                                  (v) => setState(() {}),
                                ),
                            label: '${(storage.getInt('chunk_size') ?? 25)}',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                ListView(
                  children: [
                    Row(
                      children: [
                        Text(
                          lang('music_volume', 'Music Volume') + ': ',
                          style: textStyle,
                        ),
                        SizedBox(
                          width: 20.w,
                          height: 5.h,
                          child: Slider(
                            value: storage.getDouble("music_volume")!,
                            min: 0,
                            max: 1,
                            onChanged: (v) async {
                              await storage.setDouble("music_volume", (v * 100 ~/ 1) / 100);
                              await setLoopSoundVolume(music, storage.getDouble("music_volume")!);
                              setState(() {});
                            },
                            label: '${storage.getDouble('music_volume')! * 100}%',
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          lang('sfx_volume', 'SFX Volume') + ': ',
                          style: textStyle,
                        ),
                        SizedBox(
                          width: 20.w,
                          height: 5.h,
                          child: Slider(
                            value: storage.getDouble("sfx_volume") ?? 1,
                            min: 0,
                            max: 1,
                            onChanged: (v) => storage
                                .setDouble(
                                  "sfx_volume",
                                  (v * 100 ~/ 1) / 100,
                                )
                                .then(
                                  (v) => setState(() {}),
                                ),
                            label: '${(storage.getDouble('sfx_volume') ?? 1) * 100}%',
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      width: 60.w,
                      child: Row(
                        children: [
                          Text(
                            lang('music_type', 'Music: '),
                            style: textStyle,
                          ),
                          SizedBox(
                            height: 5.h,
                            child: DropDownButton(
                              leading: Icon(FluentIcons.music_note),
                              title: Text(getCurrentMusicData().name),
                              placement: FlyoutPlacement.start,
                              items: [
                                for (var music in musics)
                                  // ignore: deprecated_member_use
                                  DropDownButtonItem(
                                    title: Text(music.name),
                                    leading: Icon(FluentIcons.music_note),
                                    onTap: () async {
                                      await changeMusic(music.id);
                                      setState(() {});
                                    },
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                ListView(
                  children: [
                    checkboxSetting(
                      'realistic_render',
                      'realistic_render',
                      'Realistic Rendering',
                      true,
                    ),
                    checkboxSetting(
                      'show_titles',
                      'titles_descriptions',
                      'Titles & Descriptions',
                      true,
                    ),
                    Row(
                      children: [
                        Text(
                          lang('ui_scale', 'UI Scale') + ': ',
                          style: textStyle,
                        ),
                        SizedBox(
                          width: 20.w,
                          height: 5.h,
                          child: Slider(
                            value: storage.getDouble("ui_scale")!,
                            min: 0.1,
                            max: 5,
                            onChanged: (v) => storage
                                .setDouble(
                                  "ui_scale",
                                  (v * 100 ~/ 1) / 100,
                                )
                                .then((v) => setState(() {})),
                            label: '${storage.getDouble('ui_scale')! * 100}%',
                          ),
                        ),
                      ],
                    ),
                    checkboxSetting(
                      'interpolation',
                      'interpolation',
                      'Interpolation',
                      true,
                    ),
                    if (storage.getBool('interpolation') == true)
                      Row(
                        children: [
                          Text(
                            lang('lerp_speed', 'Lerp Speed') + ': ',
                            style: textStyle,
                          ),
                          SizedBox(
                            width: 20.w,
                            height: 5.h,
                            child: Slider(
                              value: storage.getDouble("lerp_speed") ?? 10.0,
                              min: 0.1,
                              max: 50,
                              divisions: 500,
                              onChanged: (v) => storage
                                  .setDouble(
                                    "lerp_speed",
                                    (v * 10 ~/ 1) / 10,
                                  )
                                  .then((v) => setState(() {})),
                              label: '${storage.getDouble('lerp_speed') ?? 10.0}x',
                            ),
                          ),
                        ],
                      ),
                    checkboxSetting(
                      'cellbar',
                      'cellbar',
                      'Cell Bar',
                      false,
                    ),
                  ],
                ),
                ListView(
                  children: [
                    Row(
                      children: [
                        Text(
                          '${lang('constant_clientID', 'Client ID')}: ',
                          style: textStyle,
                        ),
                        SizedBox(
                          width: 20.w,
                          height: 5.h,
                          child: TextBox(
                            style: textBoxStyle,
                            controller: _clientIDController,
                            onChanged: (str) {
                              storage
                                  .setString(
                                    "clientID",
                                    str.replaceAll(' ', ''),
                                  )
                                  .then(
                                    (e) => setState(
                                      () {},
                                    ),
                                  );
                            },
                          ),
                        ),
                      ],
                    ),
                    checkboxSetting('local_packet_mirror', 'preprocess_packets', 'Preprocess Sent Packets', false),
                    SizedBox(
                      width: 60.w,
                      child: Row(
                        children: [
                          Text(
                            lang('cursor_texture', 'Cursor Texture: '),
                            style: textStyle,
                          ),
                          SizedBox(
                            height: 5.h,
                            child: DropDownButton(
                              leading: Image.asset("assets/images/" +
                                  ((storage.getString("cursor_texture") ?? "cursor") == "cursor"
                                      ? "interface/cursor.png"
                                      : (textureMap["${storage.getString("cursor_texture")!}.png"] ?? "${storage.getString("cursor_texture")!}.png"))),
                              title: Text((storage.getString("cursor_texture") ?? "cursor") == "cursor" ? "Default" : (cellInfo[storage.getString("cursor_texture")!] ?? defaultProfile).title),
                              placement: FlyoutPlacement.start,
                              items: [
                                for (var texture in cursorTextures)
                                  // ignore: deprecated_member_use
                                  DropDownButtonItem(
                                    title: Text(texture == "cursor" ? "Default" : (cellInfo[texture] ?? defaultProfile).title),
                                    leading: Image.asset("assets/images/" + (texture == "cursor" ? "interface/cursor.png" : (textureMap["$texture.png"] ?? "$texture.png"))),
                                    onTap: () async {
                                      await storage.setString("cursor_texture", texture);
                                      setState(() {});
                                    },
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      bottomBar: Row(
        children: [
          Spacer(),
          Button(
            child: Text(
              lang(
                'clear_storage',
                'Clear Storage',
              ),
              style: fontSize(7.sp),
            ),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) {
                  return ContentDialog(
                    title: Text(lang('warning_storage_del', 'Warning: This will delete all save files!')),
                    content: Text(lang('warning_del_msg',
                        'This will erase your save files. This means your settings will reset, your worlds will be deleted, the server list will be erased. This will also apply to all installations since they share the save files')),
                    actions: [
                      Button(
                        child: Text(lang('erase', 'Erase')),
                        onPressed: () {
                          storage.clear().then((v) {
                            fixStorage().then((v) => setState(() {}));
                          });
                          Navigator.of(ctx).pop();
                        },
                      ),
                      Button(
                        child: Text(lang('cancel', 'Cancel')),
                        onPressed: () {
                          Navigator.of(ctx).pop();
                        },
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class SettingTile {
  String settingID;
  String langKey;
  String title;
  int width;
  int height;

  SettingTile({
    required this.settingID,
    required this.langKey,
    required this.title,
    required this.width,
    required this.height,
  });

  Widget renderField(void Function() rerender) {
    return Text("Raw setting tile");
  }

  Widget renderRaw(void Function() rerender) {
    return Row(
      children: [
        Text(
          lang(langKey, title),
          style: TextStyle(
            fontSize: 9.sp,
          ),
        ),
        SizedBox(
          width: width.w,
          height: height.h,
          child: renderField(rerender),
        ),
      ],
    );
  }

  void dispose() {}
}
