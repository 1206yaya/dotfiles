import pathspec

def should_ignore(path, ignore_patterns):
    spec = pathspec.PathSpec.from_lines('gitwildmatch', ignore_patterns)
    return spec.match_file(path)


def test_should_ignore():
    pattern = "**/ios/**"
    path = "ios/b.txt"

    print(should_ignore("a.txt", ["a.txt"])) # True expected
    print(should_ignore(path, [pattern])) # True expected
test_should_ignore()
