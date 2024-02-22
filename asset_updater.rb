require "dotenv/load"
require "bundler"
Bundler.require

require "./vps_requester"
require "./gold_tracker"
require "./vni_tracker"
require "./spreadsheet_updater"

vps_net_asset = VpsRequester.new.vps_net_asset
gold_net_asset = GoldTracker.new.get_net_asset
vni_value = VniTracker.new.get_vni_value
data = vps_net_asset.merge(gold_net_asset, vni_value)

SpreadsheetUpdater.new(data).run
