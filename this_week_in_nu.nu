# fetch https://api.github.com/repos/nushell/nushell/pulls?q=is%3Apr+merged%3A%3E%3D2021-04-20+ | select html_url user.login title body
# fetch https://api.github.com/search/issues?q=repo:nushell/nushell+is:pr+is:merged+merged:%3E2021-05-08 | get items | select html_url user.login title body
# Repos to monitor

def do-work [] {
  let site_table = [
    [site repo
    ]; [Nushell nushell
    ] [Extension vscode-nushell-lang
    ] [Documentation nushell.github.io
    ] [Wasm demo
    ] [Nu_Scripts nu_scripts
    ] [RFCs rfcs]
    # ] [Jupyter jupyter]
  ]

  let query_prefix = "https://api.github.com/search/issues?q=repo:nushell/"
  let query_date = $(seq date --days 7 -r | last)
  let query_suffix = $(build-string "+is:pr+is:merged+merged:%3E%3D" $query_date)

  let entries = $(echo $site_table | each {
      let query_string = $(build-string $query_prefix $it.repo $query_suffix)
      let site_json = $(fetch $query_string | get items | select html_url user.login title body)
      build-string '## ' $(echo $it.site) $(char nl) $(char nl)
      if $(= $site_json | empty?) {
        build-string "none found this week" $(char nl) $(char nl)
      } {
        echo $site_json | group-by user_login | pivot user prs | each {
          let user_name = $it.user
          let pr_count = $(echo $it.prs | length)

          # only print the comma if there's another item
          let user_prs = $(echo $it.prs | each -n {
              if $pr_count == $(= $it.index + 1) {
                  build-string $(char nl) '### [' $it.item.title '](' $it.item.html_url ')' $(char nl) $(char nl) $it.item.body $(char nl)
              } {
                  build-string $(char nl) '### [' $it.item.title '](' $it.item.html_url ')' $(char nl) $(char nl) $it.item.body $(char nl) 'and' $(char nl)
              }
          } | str collect)

          build-string '### **' $user_name '** ' $(char nl) $(char nl) '---' $(char nl) $user_prs $(char nl)
        } | str collect
        build-string $(char nl)
      }

      # We need 2 seconds between fetches or github's api limiting will limit us
      sleep 2sec
  })

  if $(= $entries | empty?) {

  } {
    echo $entries | str collect
  }
}

# 2019-08-23 was the release of 0.2.0, the first public release
let week_num = $(seq date -b '2019-08-23' -n 7 | length)
build-string '# This week in Nushell #' $week_num $(char nl) $(char nl)
do-work | str collect
