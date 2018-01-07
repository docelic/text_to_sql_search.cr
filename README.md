# Welcome to Text To SQL Search

**Text to SQL Search** is a shard written in [Crystal](http://www.crystal-lang.org) for translating textual searches into SQL WHERE clauses. All the necessary options to configure the specifics of the translation process exist.

The search specifications are generally intended to come from three sources: free-form search inputs on websites, submitted form fields, and command lines. However, there is nothing in the code that would prevent any other uses as long as the input is text.

This shard is for you if you use an SQL data store in your application and want to generate WHERE clauses in a simpler and more user friendly way than asking users to write SQL or you manually converting form inputs into SQL or ORM wrappers syntax.

The shard works with any database for which the generated SQL WHERE clause is valid. The resulting SQL is then applicable for manual SQL search invocations, Model.all("WHERE ...") invocations in ORM models such as [Granite ORM](https://github.com/docelic/granite-orm/), and any other ORMs that support direct SQL input.

When search identifiers are recognized to be column names, generated SQL WHEREs defaults to those columns. When search terms are not identifiers, they are searched in a custom-definable set of fields with a definable operator.

## Supported Search Types

A couple examples to get you going, for example in car sale searches. All forms of spacing are tolerated - the spacing shown is chosen just for clarity how the parser will interpret the text:

```text_to_sql_search
INPUT: sedan    4 doors    > 2000 ccm    price < 20k    with    no    scratches
WHERE: "type"='sedan' AND "doors"='4' AND "ccm">'2000' AND "price"<'20000' AND not("scratches">'0')

INPUT: > 3000 ccm or with    stereo
WHERE: ccm>3000 or stereo>0

INPUT: ((4 door and color is blue) or !scratches) and price less than 5000
WHERE: ((doors=4 AND color=blue) OR not(scratches>0)) AND price<5000

INPUT: color is "metallic red" or year: 2015
WHERE: color='metallic red' or year >= 2015
```

## Installation

Ensure you have the necessary dependencies:

- `git`: Use your platform specific package manager to install `git`
- `crystal`: Follow the instructions to get `crystal` on this page: <https://crystal-lang.org/docs/installation/index.html>

Then:

```shellsession
$ git clone https://github.com/docelic/text_to_sql_search.cr.git
$ cd text_to_sql_search.cr
$ make
$ make spec
```

## Contributing

1. Fork it (https://github.com/docelic/text_to_sql_search.cr/fork)
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details
