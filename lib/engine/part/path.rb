# frozen_string_literal: true

require_relative 'base'

module Engine
  module Part
    class Path < Base
      attr_reader :a, :b, :branch, :city, :edges, :junction, :node, :offboard, :stop, :town

      def self.walk(paths, visited: {}, on: nil)
        paths.each do |path|
          path.walk(visited: visited, on: on) { |p| yield p }
        end
      end

      def initialize(a, b)
        @a = a
        @b = b
        @edges = []

        separate_parts
      end

      def <=>(other)
        id <=> other.id
      end

      def <=(other)
        (@a <= other.a && @b <= other.b) ||
          (@a <= other.b && @b <= other.a)
      end

      def select(paths)
        on = paths.map { |p| [p, 0] }.to_h

        walk(on: on) do |path|
          on[path] = 1 if on[path]
        end

        on.keys.select { |p| on[p] == 1 }
      end

      def walk(skip: nil, visited: {}, on: nil)
        return if visited[self]

        visited[self] = true
        yield self

        exits.each do |edge|
          next if edge == skip

          np_edge = hex.invert(edge)
          next unless (neighbor = hex.neighbors[edge])

          neighbor.paths[np_edge].each do |np|
            next if on && !on[np]

            np.walk(skip: np_edge, visited: visited, on: on) { |p| yield p }
          end
        end
      end

      def path?
        true
      end

      def exits
        @edges.map(&:num)
      end

      def rotate(ticks)
        path = Path.new(@a.rotate(ticks), @b.rotate(ticks))
        path.index = index
        path.tile = @tile
        path
      end

      def inspect
        name = self.class.name.split('::').last
        "<#{name}: hex: #{hex&.name}, exit: #{exits}>"
      end

      private

      def separate_parts
        [@a, @b].each do |part|
          case
          when part.edge?
            @edges << part
          when part.offboard?
            @offboard = part
            @stop = part
            @node = part
          when part.city?
            @city = part
            @branch = part
            @stop = part
            @node = part
          when part.junction?
            @junction = part
            @branch = part
            @node = part
          when part.town?
            @town = part
            @branch = part
            @stop = part
            @node = part
          end
        end
      end
    end
  end
end
