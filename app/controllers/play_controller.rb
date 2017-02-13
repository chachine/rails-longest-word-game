require 'open-uri'
require 'json'

class PlayController < ApplicationController
  def game
    @start_time = Time.now
    @grid = Array.new(9) { ('A'..'Z').to_a[rand(26)] }
    session[:grid] = @grid
    session[:start_time] = @start_time

  end

  def score
    @attempt = params[:word]
    @start_time = session[:start_time]
    @end_time = Time.now
    @grid = session[:grid]
    @result = run_game(@attempt, @grid, @start_time, @end_time)
  end

    def score_and_message(attempt, translation, grid, time)
      if included?(attempt.upcase, grid)
        if translation
          score = compute_score(attempt, time)
          [score, "well done"]
        else
          [0, "not an english word"]
        end
      else
        [0, "not in the grid"]
      end
    end

    def included?(guess, grid)
      guess_arr = guess.split('')
      guess_arr.all? { |letter| guess_arr.count(letter) <= grid.count(letter) }
    end

    def compute_score(attempt, time_taken)

      (time_taken > 60.0) ? 0 : attempt.size * (1.0 - time_taken / 60.0)
    end

    def run_game(attempt, grid, start_time, end_time)
      @result = { time: @end_time.to_time - @start_time.to_time }
       @result[:end_time] = @end_time
       @result[:start_time] = @start_time

      @result[:translation] = get_translation(attempt)
      @result[:score], @result[:message] = score_and_message(attempt, @result[:translation], grid, @result[:time])

      @result
    end

    def get_translation(word)
      api_key = "6a978208-f5a4-44e9-9f0e-a636a93c1e8f"
      begin
        response = open("https://api-platform.systran.net/translation/text/translate?source=en&target=fr&key=#{api_key}&input=#{word}")
        json = JSON.parse(response.read.to_s)
        if json['outputs'] && json['outputs'][0] && json['outputs'][0]['output'] && json['outputs'][0]['output'] != word
          return json['outputs'][0]['output']
        end
      rescue
        if File.read('/usr/share/dict/words').upcase.split("\n").include? word.upcase
          return word
        else
          return nil
        end
      end
    end

  end
