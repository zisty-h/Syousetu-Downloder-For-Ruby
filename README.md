﻿# Syousetu-Downloder-For-Ruby
## クリエイター
プログラム作成者: tanahiro2010<br>
所属チーム: Zisty<br>
YouTube: https://www.youtube.com/@tanahiro2010<br>
Twitter: https://twitter.com/tanahiro2010<br>

## ソフトの説明
main.rb、Soft.rbともに小説家になろうにある小説を一括ダウンロードするソフトです。
### main.rb
このプログラムは非公式APIを作成しようと、開発しました。<br>
http://localhost:4567 にget要求をすると"Hello world!"が返されます。<br>
私はサーバーが起動しているか確かめるのに使用します.<br>
そして、http://localhost:4567/book?ncode={小説家になろうにある小説のncode} にアクセスすると、すこしレスポンスに時間はかかりますが現在公開されている小説の全話が表示されます。

### Soft.rb
主な機能はmain.rbと同じです。<br>
違う部分がこのプログラムはAPI関係なくソフトとして扱うという点です。<br>
このプログラムを実行すると、ncodeの入力が求められます<br>
入力すると、ダウンロードが始まります。
全話のダウンロードが終了すると、Soft.rbがあるフォルダーに小説のタイトルのテキストファイルが作成されます。<br>
そのファイルに全話の内容が記述されてあります。

## AllFunctions.rb
わけわからんことになってます<br>
私（作者）が学校で使うようにいろいろとアップデートしていってるコードです<br>
## 開発環境構築(Windowsの場合は管理者権限cmd使用)
### Linuxの場合
```bash
sudo su
apt install ruby
gem install nokogiri
gem install json
gem install sinatra
```

### Windowsの場合
```cmd
choco install ruby
gem install nokogiri
gem install json
gem install sinatra
```

## 実行方法
```bash
cd "main.rb or Soft.rb or GoogleDrive-shere.rbがあるフォルダーパス"
ruby "実行したいプログラムネーム"
```
