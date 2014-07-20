require 'rubygems'
require 'sinatra'
require 'sinatra/reloader' if development?

set :sessions, true
BLACKJACK_AMOUNT = 21
DEALER_MIN_HIT = 17

helpers do
  def calculate_total(cards) #[[suit, card],[ 'H', '3']]
    values = cards.map{|e| e[1]}
    score = 0
    values.each do |card|
      if card == 'Ace'
        score+=11
      elsif card.to_i == 0 # Jack, Queen or King
        score += 10
      else
        score += card.to_i
      end
    end
    #correct for aces
    values.select{|e| e == 'Ace'}.count.times do
      score -=10 if score > BLACKJACK_AMOUNT
      # e = ['A'] #change value of card to something similar
    end
    score
  end

  def card_image(card)
    "<img src='/images/cards/#{card[0]}_#{card[1]}.jpg' class='image-polaroid'>"
  end
  
  def winner!(msg)
    @show_hit_or_stay_buttons = false
    @game_over = true
    session[:bank] = session[:bank] + session[:new_bet] 
    @winner = "<strong>#{session[:player_name]}</strong> wins! #{msg}."
  end

  def loser!(msg)
    @show_hit_or_stay_buttons = false
    @game_over = true
    session[:bank] = session[:bank] - session[:new_bet]
    @loser = "<strong>#{session[:player_name]}</strong> loses! #{msg}." 
  end

  def tie!(msg)
    @show_hit_or_stay_buttons = false
    @game_over = true
    @winner = "<strong>#{session[:player_name]}</strong> wins! #{msg}."
  end

end

before do
  @show_hit_or_stay_buttons = true
  @game_over = false
  @show_dealer_hit_button = false
end

get '/' do
  if session[:player_name]
    redirect '/bet'
  else
    redirect '/new_player'
  end
end

get '/new_player' do
  erb :new_player
end

post '/set_name' do
  if params[:player_name].empty?
    @error = "Name is required"
    halt erb :new_player
  end

  session[:player_name] = params[:player_name]
  session[:bank] = 500
  redirect '/bet'
end

get '/bet' do
  session[:new_bet] = nil
  erb :bet
end

post '/set_bet' do
  @bank = session[:bank]
  session[:new_bet] = params[:new_bet].to_i

  if params[:new_bet].nil? || params[:new_bet].to_i == 0
    @error = "Must make a bet."
    halt erb(:erb)
  elsif params[:new_bet].to_i > session[:bank]
    @error = "Hey buddy, don't bet more than $#{session[:bank]}!"
  else
    session[:new_bet] = params[:new_bet].to_i
    redirect 'game'
  end
end

get '/game' do
  #Set player turn
  session[:turn] = session[:player_name]

  #Create a deck and store in session
  suit = ["hearts", "clubs", "diamonds", "spades"]
  values = ['2','3','4','5', '6', '7', '8', '9', '10', 'Jack', 'Queen', 'King', 'Ace']
  session[:deck] = suit.product(values).shuffle!

  #deal cards
  session[:player_cards] = []
  session[:dealer_cards] = []
  session[:dealer_cards] << session[:deck].pop
  session[:player_cards] << session[:deck].pop
  session[:dealer_cards] << session[:deck].pop
  session[:player_cards] << session[:deck].pop
  
  erb :game
end

post '/game/player/hit' do
  session[:player_cards] << session[:deck].pop
  player_total = calculate_total(session[:player_cards])
  if player_total == BLACKJACK_AMOUNT
    winner!("#{session[:player_name]} hit blackjack.")
  elsif player_total > BLACKJACK_AMOUNT
    loser!("It looks like #{session[:player_name]} busted at #{player_total}.")
  end
  erb :game, layout: false 
end

get '/game/BlackJack' do

  erb :blackjack
end


post '/game/player/stay' do
  @success = "#{session[:player_name]} has chosen to stay."
  @show_hit_or_stay_buttons = false
  redirect '/game/dealer'
end

get '/game/dealer' do
  session[:turn] = "dealer"
  @show_hit_or_stay_buttons = false
  
  #decision tree
  dealer_total = calculate_total(session[:dealer_cards]) 
  
  if  dealer_total == BLACKJACK_AMOUNT 
    loser!("Dealer hit BlackJack!")
  elsif dealer_total > BLACKJACK_AMOUNT
    winner!("Dealer busted at #{dealer_total}!")
  elsif dealer_total >= DEALER_MIN_HIT #17, 18, 19, 20
    # dealer stays
    redirect '/game/compare'
  else
    # dealer hits
    @show_dealer_hit_button = true
  end

  erb :game, layout: false 
end

post '/game/dealer/hit' do
  session[:dealer_cards] << session[:deck].pop
  redirect '/game/dealer'
end

get '/game/compare' do
  @show_hit_or_stay_buttons = false

  player_total = calculate_total(session[:player_cards])
  dealer_total = calculate_total(session[:dealer_cards])

   if player_total < dealer_total
    loser!("#{session[:player_name]} stayed at #{player_total}, and the dealer stayed at #{dealer_total}.")
  elsif player_total > dealer_total
    winner!("#{session[:player_name]} stayed at #{player_total}, and the dealer stayed at #{dealer_total}.")
  else
    tie!("Both #{session[:player_name]} and the dealer stayed at #{player_total}.")
  end
  
  erb :game, layout: false 
end

get '/game/BlackJack/compare' do
  @show_hit_or_stay_buttons = false

  player_total = calculate_total(session[:player_cards])
  dealer_total = calculate_total(session[:dealer_cards])

   if player_total < dealer_total
    loser!("#{session[:player_name]} stayed at #{player_total}, and the dealer stayed at #{dealer_total}.")
  elsif player_total > dealer_total
    winner!("#{session[:player_name]} stayed at #{player_total}, and the dealer stayed at #{dealer_total}.")
  else
    tie!("Both #{session[:player_name]} and the dealer stayed at #{player_total}.")
  end
  
  erb :game
end

get '/game_over' do
  erb :game_over
end

