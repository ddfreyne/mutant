# encoding: utf-8

Mutant::Meta::Example.add do

  source ':"foo#{bar}baz"'

  mutation ':"#{nil}#{bar}baz"'
  mutation ':"foo#{bar}#{nil}"'
  mutation ':"foo#{nil}baz"'
  mutation 'nil'
end
