require "dotenv/load"
require "mechanize"
require "bundler"

Bundler.require

class GoldTracker
  BASE_URL = 'https://trangsuc.doji.vn/bang-gia-vang'

  def get_net_asset
    agent = Mechanize.new

    page = agent.get(BASE_URL)

    gold_ring_element = page.search("tr td").detect {|td| td.text == "Nhẫn Tròn 9999 Hưng Thịnh Vượng"}

    sell_price = gold_ring_element.next.next.text.gsub(',','').to_i

    {
      gold_asset: (sell_price * ENV["GOLD_AMOUNT"].to_f).to_i
    }
  end
end
