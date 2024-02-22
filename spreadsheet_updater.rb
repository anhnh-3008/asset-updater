require "dotenv/load"
require "bundler"
Bundler.require

class SpreadsheetUpdater
  def initialize data = {}
    @data = data
  end

  def run
    updated_data.each.with_index(1) do |value, index|
      sheet[today_row_index, index] = value
    end

    sheet.save
  end

  private
  attr_accessor :sheet, :data

  def updated_data
    [
      today,
      (data[:gold_asset] || sheet[yesterday_row_index, 2].split(',')[0].gsub('.', '')),
      (data[:vps_normal] || sheet[yesterday_row_index, 3].split(',')[0].gsub('.', '')),
      "=SUM(B#{today_row_index}:C#{today_row_index})",
      today_row_index == 2 ? "=0%" : "=(B#{today_row_index}-B2) / B2 * 100%",
      today_row_index == 2 ? "=0%" : "#{modified_dietz(today_row_index, :stock)}%".gsub('.', ','),
      today_row_index == 2 ? "=0%" : "#{modified_dietz(today_row_index, :asset)}%".gsub('.', ','),
      (data[:vnindex] || sheet[yesterday_row_index, 8].split(',')[0].gsub('.', '')),
      today_row_index == 2 ? "=0%" : "=(H#{today_row_index}-H2) / H2 * 100%",
      0
    ]
  end

  def sheet
    return @sheet unless @sheet.nil?

    session = GoogleDrive::Session.from_service_account_key(ENV["CLIENT_SECRET_FILE_PATH"])
    spreadsheet = session.spreadsheet_by_key(ENV["SPREADSHEET_ID"])
    @sheet = spreadsheet.worksheet_by_title(ENV["WORKSHEET_TITLE"])
  end

  def today
    @today ||= Time.now.strftime("%d/%m/%Y")
  end

  def today_row_index
    today_row_index = sheet.rows.find_index {|row| row[0] == today}
    today_row_index.nil? ? sheet.rows.size + 1 : today_row_index + 1
  end

  def yesterday_row_index
    @yesterday_row_index ||= today_row_index - 1
  end

  def modified_dietz(index, type_asset)
    index_asset = case type_asset
                  when :asset
                    4
                  when :stock
                    3
                  when :gold
                    2
                  else
                    nil
                  end

    return 0 if index_asset.nil?


    v0 = convert_string_to_cash(sheet[2, index_asset])
    v1 = convert_string_to_cash(sheet[index, index_asset])
    total_cash_flow = sheet.rows[1..index-1].inject(0){ |sum, row| sum + convert_string_to_cash(row[9]) }
    numerator = v1 - v0 - total_cash_flow

    date_first = sheet[2, 1]
    date_last = sheet[index, 1].nil? ? today : sheet[index, 1]
    duration = duration_date(date_last, date_first)
    total_cash_flow_by_time = sheet.rows[1..index-1].inject(0){ |sum, row| sum + ((duration - duration_date(row[0], date_first)) / duration)*convert_string_to_cash(row[9]) }
    denominator = v0 + total_cash_flow_by_time

    (numerator / denominator * 100).round(2)
  end

  def convert_string_to_cash(str)
    str.gsub(" đ","").gsub(".","").to_i
  end

  def duration_date(date_last_str, date_first_str)
    (Time.parse(date_last_str) - Time.parse(date_first_str)) / (24*60*60)
  end
end
