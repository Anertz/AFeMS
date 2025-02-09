<h1> A Fabric enabled Minecraft Server ✨</h1>

### 頭文字を取って<b>AFeMS</b>！

> [!IMPORTANT]
> ### 可能な限り<b>EASY</b>にしました！自信あります</p>


# 📜 導入済Mods
[ここ](https://github.com/Anertz/AFeMS/tree/main/mods)をクリック

# ⚙️ 準備

以下をインストールしてください

- [Git](https://github.com/git-for-windows/git/releases/download/v2.47.1.windows.2/Git-2.47.1.2-64-bit.exe)
< そのままいじらないで進めてください
- [Fabric](https://maven.fabricmc.net/net/fabricmc/fabric-installer/1.0.1/fabric-installer-1.0.1.exe)
< インストール時に、<b>Minecraft v1.20.1</b>を選択

> [!IMPORTANT]
> ### インストールが終わったら、再起動してください



# 🚀 Modsのインストール

1. Windowsキー + Rを押し、`powershell`と入力してターミナルを起動
2. 以下をコピペしてターミナルでEnterキーで実行
```bash
curl https://raw.githubusercontent.com/Anertz/AFeMS/main/installer.ps1 | iex  
```
`Mods are installed!`と表示されたら次に進んでください

> [!WARNING]
> エラーが出た場合は、再起動してないかGitが未インストールです

3. Minecraft Laucherを起動
4. 上の起動構成をクリック
5. `fabric-loader-1.20.1`の・・・から編集をクリック

<p float="left">
  <img src="https://raw.githubusercontent.com/Anertz/AFeMS/main/imgs/20250118_05h48m06s_grim.png"/>
</p>

6. ゲームディレクトリ欄をクリックしてControlキー + V

<img src="https://raw.githubusercontent.com/Anertz/AFeMS/main/imgs/20250118_17h50m55s_grim.png"/>

7. `C:\Users\<自分のユーザー名>\AFeMS`になっていることを確認して、保存して完了です


> [!NOTE]
> ### 📁 Modsが更新された場合は以下をターミナルで実行してください
> [Release](https://github.com/Anertz/AFeMS/releases)でお知らせします
> ```bash
> cd AFeMS | git pull
> ```

# ✅ 準備はすべて完了です！
### Discordに貼ってあるIPアドレスからサーバーに参加してください！
何か不明点、不具合があったなら遠慮なく[issues](https://github.com/Anertz/AFeMS/issues)または管理者に問い合わせてください。

# 🔥パフォーマンスの最適化
### すでに多くの最適化Modによって十分に最適化されていますが、以下を試してさらにパフォーマンスを最適化できます。
- GraalVM Enterprise Editionを以下の引数で起動
```bash
-Xms8G -Xmx8G -XX:+UnlockExperimentalVMOptions -XX:+UnlockDiagnosticVMOptions -XX:+AlwaysActAsServerClassMachine -XX:+AlwaysPreTouch -XX:+DisableExplicitGC -XX:+UseNUMA -XX:AllocatePrefetchStyle=3 -XX:NmethodSweepActivity=1 -XX:ReservedCodeCacheSize=400M -XX:NonNMethodCodeHeapSize=12M -XX:ProfiledCodeHeapSize=194M -XX:NonProfiledCodeHeapSize=194M -XX:-DontCompileHugeMethods -XX:+PerfDisableSharedMem -XX:+UseFastUnorderedTimeStamps -XX:+UseCriticalJavaThreadPriority -XX:+EagerJVMCI -Dgraal.TuneInlinerExploration=1 -Dgraal.CompilerConfiguration=enterprise -XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 -XX:G1NewSizePercent=40 -XX:G1MaxNewSizePercent=50 -XX:G1HeapRegionSize=16M -XX:G1ReservePercent=15 -XX:G1HeapWastePercent=5 -XX:G1MixedGCCountTarget=4 -XX:InitiatingHeapOccupancyPercent=20 -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:SurvivorRatio=32 -XX:MaxTenuringThreshold=1 -Dusing.aikars.flags=https://mcflags.emc.gs -Daikars.new.flags=true
```
- Wayland環境下ではXwaylandの代わりにWaylandで起動(Linux)
