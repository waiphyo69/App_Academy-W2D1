require 'byebug'

class Board
  SIZE = 9

  BOMBS = 10

  attr_reader :grid

  def initialize
    @grid = Array.new(SIZE){Array.new(SIZE)}

    (0...SIZE).each do |i|
      (0...SIZE).each do |j|
        self[[i, j]] = Tile.new(self, [i, j])
      end
    end
  end

  def [](pos)
    @grid[pos[0]][pos[1]]
  end

  def []=(pos, tile)
    @grid[pos[0]][pos[1]] = tile
  end

  def set_bombs
    bombs = []
    until bombs.length == BOMBS
      rand_pos = [rand(SIZE),rand(SIZE)]
      unless bombs.include?(rand_pos)
        bombs << rand_pos
        self[rand_pos].bomb = true
      end
    end
  end

  def print_board
    top_row = [' ']
    SIZE.times { |i| top_row << i.to_s }
    puts top_row.join(' | ')

    @grid.each_with_index do |row, i|
      display_row = [i.to_s]

      row.each do |tile|
        if tile.flagged
          display_row << 'F'
        elsif tile.revealed == false
          display_row << '*'
        elsif tile.bomb == true
          display_row << 'B'
        elsif tile.neighbor_bombs > 0
          display_row << tile.neighbor_bombs.to_s
        elsif tile.neighbor_bombs == 0
          display_row << '_'
        end
      end

      puts display_row.join(' | ')
    end
  end

  def win?
    flags = 0

    @grid.flatten.each { |tile| flags += 1 if tile.flagged }

    shown = @grid.flatten.all? do |tile|
      tile.revealed || tile.flagged || tile.bomb
    end

    shown && flags <= BOMBS
  end

  def over
    @grid.flatten.each do |tile|
      tile.revealed = true
    end
  end
end

class Tile
  DELTAS = [
    [0,1],
    [0,-1],
    [1,0],
    [1,1],
    [1,-1],
    [-1,1],
    [-1,-1],
    [-1,0]
  ]

  attr_accessor :bomb, :flagged, :revealed
  attr_reader :pos, :board

  def initialize(board, pos)
    @board = board
    @pos = pos
    @bomb = false
    @flagged = false
    @revealed = false
  end

  def neighbor_bombs
    count = 0
    neighbors.each do |pos|
      count += 1 if board[pos].bomb
    end

    count
  end

  def empty?
    neighbor_bombs == 0
  end

  def reveal
    return if revealed || flagged

    self.revealed = true

    if neighbor_bombs == 0
      neighbors.each do |pos|
        board[pos].reveal
      end
    end
  end

  private
  def neighbors
    neighbors = DELTAS.map do |delta|
      [pos[0] + delta[0], pos[1] + delta[1]]
    end

    size = board.grid.length
    neighbors.select do |p|
      p[0] >= 0 && p[0] < size && p[1] >= 0 && p[1] < size
    end
  end
end


class Game
  attr_reader :board

  def initialize
    @board = Board.new
  end

  def play
    board.set_bombs
    board.print_board

    until board.win?
      pos = get_position
      action = get_action(pos)
      if action == 'r'
        if board[pos].bomb
          puts "Sorry, you lose."
          board.over
          board.print_board
          return
        else
          board[pos].reveal
        end
      else
        board[pos].flagged = !board[pos].flagged
      end

      board.print_board
    end

    puts "Congrats, you win!"
    board.print_board
  end

  private
  def get_position
    pos = []

    puts "Which row would you like?"
    pos << Integer(gets.chomp)

    puts "Which column would you like?"
    pos << Integer(gets.chomp)

    raise "Invalid position" if self.board[pos].revealed

    pos
  end

  def get_action(pos)
    puts "Do you want to reveal or flag (r or f)?"
    action = gets.chomp.downcase

    raise "Invalid input." unless action == 'r' or action == 'f'

    action
  end
end
