# git-secret fork

This is a fork from the original [git-secret](https://github.com/sobolevn/git-secret) project. This fork improves the
sequence of steps to handle encryption and decryption of secret files and simplifies the handling of branch merges, outlying
differences between versions using standard git conflicts markers.

## Wtf? - Why the fork?

For a work related project, I needed to introduce `git-secret` into our CI/CD system. While it improved and simplified
the configuration management process, it greatly complicated the development part. The original `git-secret` is not
very user-friendly when you need to manage multiple branches at the same time.

The issues is due to the fact that plain text files are not versioned, therefore it is difficult to keep track of the evolution
between branches. The only tool provided is `git secret changes`: it outputs the differences in a `diff`-style format, which
is machine-oriented, but does not provide clear visual hints, nor context, about the changes (i.e. it does not output the full file,
but only the changed lines).

Therefore, I decided to extend the original functionality of `git secret changes`, `git secret hide` and `git secret reveal`,
adding the possibility to visualize differences in a git-style format, preventing the hide when conflicts are not resolved
and automatically marking conflicts when decrypting.
 
I created few PRs to the original `git secret` project ([#340](https://github.com/sobolevn/git-secret/pull/340),
[#358](https://github.com/sobolevn/git-secret/pull/358)), but those were rejected, therefore I was forced to apply
the improvements on my repository so that I can use them at work.
I should be keeping this fork updated with the original project as much as I can, and I will deprecate it when the
missing functionality will be added to the original `git secret`.

## New functionality

- `git secret reveal -s` (-s as in *safe*): decrypts secrets and automatically updates local files (if present), marking all
changes with git-style markers. This avoids the use of `git secret reveal -f`, which might lead to accidental overwrite and
also avoids the need of renaming a file if it is already present. As it modifies local content, `git secret reveal -s`
will prevent, with an error message, to be run again till all conflicts have been resolved.  

- `git secret hide -s` (-s as in *safe*): checks that there are no conflicts (parses the files to hide looking for git-style markers)
and automatically calls `git secret hide -m -d`, to encrypt only modified files and to delete the plain text afterwards.

- `git secret changes -g` (-g as in *git* style): compares the plaintext file and the encrypted file outputting **ALL** differences surrounded by
the usual git-style markers. It is used internally by git `secret reveal -s`and `git secret hide -s`, but it can be used
as stand alone.

The default behavior of these commands has not changed and they remain 100% compatible with the original ones, that is they
accept the same flags and parameters as the original `git secret reveal`, `git secret hide`, `git secret changes`.

## Example

You are working on file1 in a feature branch. This is its content:

```yaml
environment:
  base_branch: master
  branch: this_is_the_same_for_both_files
```

When you are done, you import file1.secret from master branch using `git checkout master file1.secret`.
This is the content of the encrypted file1.secret

```yaml
environment:
  base_branch: a_different_base_branch
  branch: this_is_the_same_for_both_files
  a_new_key: the_new_key_value
```

After running `git secret reveal -s`, the content of file1 is:

```yaml
environment:
<<<<< file-on-disk
  base_branch: master
=====
  base_branch: a_different_base_branch
>>>>> content-from-secret
  branch: this_is_the_same_for_both_files
<<<<< file-on-disk
=====
  a_new_key: the_new_key_value
>>>>> content-from-secret
```

As we don't version file1, but only file1.secret, the markers do not contain reference to the
version nor to the file name, but only `file-on-disk` or `content-from-secret` to inform the user
from where the changes come from.

## How to install

As this is a fork, no package will be built nor distributed. You have to clone locally this repository,
build it and add the project folder to your path. The name of the command will be `git-secret`. Please note the dash.
For more information on how to build it, please have a look to the original project: [https://github.com/sobolevn/git-secret](https://github.com/sobolevn/git-secret).

## License

MIT. See [LICENSE.md](LICENSE.md) for details.

## Thanks

Special thanks to [sobolevn](https://github.com/sobolevn) for the original project.
