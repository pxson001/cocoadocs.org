class ReadmeGenerator
  include HashInit
  attr_accessor :spec, :readme_location, :active_folder

  def create_readme
    return if $skip_downloading_readme

    markdown = ""
    spec_readme = readme_path @spec

    unless spec_readme
      spec_readme = generated_readme
    else

    end

    markdown = github_readme spec_readme
    File.open(readme_location, 'w') { |f| f.write(markdown) }
  end

  def github_readme spec_readme
    vputs "Getting README Generated by Github"
    readme_folder = @readme_location.split("/")[0...-1].join("/")
    `mkdir -p '#{readme_folder}'`

    context = nil
    context = "#{@spec.or_user}/#{@spec.or_repo}" if @spec.or_is_github?

    # this is just an empty github app that does nothing
    Octokit.client_id = '52019dadd0bc010084c4'
    Octokit.client_secret = 'c529632d7aa3ceffe3d93b589d8d2599ca7733e8'
    Octokit.markdown(File.read(spec_readme), :mode => "markdown", :context => context)
  end

  def readme_path spec
    download_location = $active_folder + "/download/#{spec.name}/#{spec.version}/#{spec.name}"
    ["README.md", "README.markdown", "README.mdown"].each do |potential_name|
      potential_path = download_location + "/" + potential_name
      if File.exists? potential_path
        return potential_path
      end
    end
    nil
  end


  def generated_readme
    download_location = $active_folder + "/download/#{spec.name}/#{spec.version}/#{spec.name}/README.md"

    license = @spec.or_license_name_and_url

    text = %Q(
# #{ @spec.name }

### #{@spec.summary }

#{ @spec.description }

### Installation

```ruby
pod '#{ @spec.name }'
```

### Authors

#{ @spec.or_contributors_to_spec }

### License

<a href="#{license[:url]}">#{license[:license]}</a>
    )

    `touch #{download_location}`
    File.open(download_location, 'w') { |f| f.write(text) }
    download_location
  end
end