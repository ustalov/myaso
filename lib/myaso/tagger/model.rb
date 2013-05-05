# encoding: utf-8

# Any HMM tagger requires a trained model that can perform such tasks as
# producing smoothed q() and e() values, replace unknown words with special
# symbols.
#
class Myaso::Tagger::Model
  attr_reader :ngrams, :lexicon, :interpolations

  # Tagging model requires n-grams and lexicon.
  #
  # It is possible to the the interpolations vector when its values are
  # known. If there are necessity to recompute the interpolations then
  # nil shall be given (default behavior). If there should be no
  # interpolations then false shall be given. In other cases it is possible
  # to set them explicitly.
  #
  def initialize(interpolations = nil)
    @ngrams, @lexicon = Myaso::Ngrams.new, Myaso::Lexicon.new
    @interpolations = if interpolations == false
      [0.33, 0.33, 0.33]
    elsif interpolations.nil?
      nil
    else
      interpolations
    end
    learn!
  end

  # Linear interpolation model of processing probability of
  # occurence of the trigram (first, second, third). It
  # consider three summands: the first one has the next sense:
  # probability that current tag is (third) if last two are
  # (first, second), the second one -- that last one is (second),
  # and the last summand consider independent probability that
  # current tag is (third).
  #
  def q(first, second, third)
    q1 = if (q1_denominator = ngrams.unigrams_count).zero?
      0
    else
      ngrams[third] / q1_denominator.to_f
    end

    q2 = if (q2_denominator = ngrams[second]).zero?
      0
    else
      ngrams[second, third] / q2_denominator.to_f
    end

    q3 = if (q3_denominator = ngrams[first, second]).zero?
      0
    else
      ngrams[first, second, third] / q3_denominator.to_f
    end

    q1 * interpolations[0] + q2 * interpolations[1] + q3 * interpolations[2]
  end

  # Function e in the Viterbi algorithm. It process probability of
  # generation word with this tag relatively to all words with
  # this tag.
  #
  def e(word, tag)
    return 0.0 if ngrams[tag].zero?
    lexicon[word, tag] / ngrams[tag].to_f
  end

  # If word is rare, than it should be replaced in preparation of the
  # training set. So, it can't be in the training set.
  #
  def rare?(word)
    lexicon[word] <= 1
  end
end
