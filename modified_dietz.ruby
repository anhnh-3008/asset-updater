require "dotenv/load"
require "bundler"
require "date"
Bundler.require

class ModifiedDietzCalculator
  # Khởi tạo với giá trị đầu kỳ, giá trị cuối kỳ, và dòng tiền
  attr_accessor :sheet, :cash_flows

  def initialize; end

  def spreadsheet
    return @sheet unless @sheet.nil?

    session = GoogleDrive::Session.from_service_account_key(ENV["CLIENT_SECRET_FILE_PATH"])
    spreadsheet = session.spreadsheet_by_key(ENV["SPREADSHEET_ID"])
    @sheet = spreadsheet.worksheet_by_title("Stock Tracking")
    @cash_flows = @sheet.rows[1..-1]
  end

  # Tính toán tỷ suất lợi nhuận
  def process
    spreadsheet

    start_date = @cash_flows[0][0]
    end_date = @cash_flows[-1][0]
    start_value = @cash_flows[0][1].to_f
    total_days = total_days_in_period(start_date, end_date)
    returns = []

    @cash_flows.each.with_index do |row, index|
      current_date = row[0]

      days_since_start = total_days_in_period(start_date, current_date)
      total_cash_flows_current = total_cash_flows(index)
      p total_cash_flows_current
      end_value = row[1].to_f
      return_rate = (calculate_return(total_days, days_since_start, start_value, end_value, total_cash_flows_current)*100).round(2)

      returns << [current_date, return_rate]
    end

    # Ghi kết quả return rate vào cột thứ 4 của sheet
    @cash_flows.each.with_index do |row, index|
      current_date = row[0]
      return_rate = returns[index][1]
      p return_rate
      @sheet[index + 2, 4] = return_rate.to_s.gsub(".", ",") + "%"
    end

    # Lưu thay đổi vào sheet
    @sheet.save


    returns[1..-1]
  end


  private

  def calculate_return(total_days, days_since_start, start_value, end_value, total_cash_flows_current)
    total_weighted_cash_flows = @cash_flows.sum { |row| row[2].to_f * (total_days - days_since_start).to_f / total_days }

    (end_value - start_value - total_cash_flows_current ) / ( start_value + total_weighted_cash_flows )
  end

  # Tổng số ngày trong kỳ
  def total_days_in_period(start_date, end_date)
    (Date.parse(end_date) - Date.parse(start_date)).to_i
  end

  # Tổng dòng tiền ròng
  def total_cash_flows(index)
    @cash_flows[1..index].sum do |row|
      cash = row[2].to_s.gsub(" đ", "").gsub(".", "").to_f / 1_000_000
    end
  end
end

# Tính toán tỷ suất lợi nhuận
calculator = ModifiedDietzCalculator.new
returns = calculator.process

# # In kết quả
# returns.each do |date, return_rate|
#   puts "#{date}: #{return_rate}"
# end
