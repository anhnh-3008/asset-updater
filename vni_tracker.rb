require "dotenv/load"
require "mechanize"
require "bundler"

Bundler.require

class VniTracker
  BASE_URL = 'https://24hmoney.vn/indices/vn-index'

  def get_vni_value
    agent = Mechanize.new

    page = agent.get(BASE_URL)

    vni_value = page.search('span.price').first.text
    replacements = { "." => ",", "," => "." }

    {
      vnindex: vni_value.gsub(Regexp.union(replacements.keys), replacements).chop
    }
  end

  private
  def search_data(table, row_text, column)
    row = table.search('tr').find do |r|
      r.text.include?(row_text)
    end

    row.search('td')[column].text.strip
  end
end
