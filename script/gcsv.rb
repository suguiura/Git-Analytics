
$: << File.join(File.dirname(__FILE__), '.')
require 'config'

module GitAnalytics
  module GCSV
    
    def self.open(filename)
      @file = File.open(filename, 'w')
      @file.puts header.join("\t")
    end
    
    def self.store(log)
      signatures = log[:signatures].map do |signature|
        p = signature[:person]
        [p[:email], p[:domain], split_domain(p[:domain])]
      end
      @file.puts [
        log[:origin],
        log[:project],
        log[:description],
        log[:author][:name],
        log[:author][:email],
        log[:author][:domain],
        split_domain(log[:author][:domain]),
        log[:author][:date],
        log[:committer][:name],
        log[:committer][:email],
        log[:committer][:domain],
        split_domain(log[:committer][:domain]),
        log[:committer][:date],
        log[:committer][:date].to_i - log[:author][:date].to_i,
        log[:tag],
        log[:message].dump[1..-2],
        log[:message].length,
        log[:modifications].size,
        log[:modifications].inject(0){|memo, x| memo + x[:linechanges]},
        fill_array(log[:modifications].map{|x| x[:path]}, 100),
        fill_array(signatures, 8, 6)
      ].join("\t") rescue (p log; exit)
    end

    private

    def self.fill_array(array, totalfields, fieldsize=1)
      n = fieldsize * totalfields
      array.flatten!
      array[n] = nil
      array[0, n]
    end

    $cctld = "(%s)" % $config[:cctlds].join('|')
    $gtld = "(%s)" % $config[:gtlds].join('|')
    $re_tlds = /((.*)\.([^\.]+))?(\.#{$gtld}\.#{$cctld}|\.#{$cctld}|\.#{$gtld})$/
    def self.split_domain(domain)
      a, b, c, d, e, f, g, h = $re_tlds.match(domain).captures rescue []
      department, organization, gtld, cctld = b, c, (e || h), (f || g)
      [department, organization, gtld, cctld]
    end

    def self.cat_and_spawn(prefix, suffixes, n)
      array = [prefix].product(suffixes)
      array = array.product(n.times.map{|x| "[#{x}]"}) if n > 1
      array.map{|x| x.join}
    end

    def self.header
      email = %w(email email_domain email_department email_company email_gtld email_cctld)
      attribs = ['name', email, 'date'].flatten

      [
        'origin',
        'project',
        'description',
        cat_and_spawn('author '       , attribs, 1),
        cat_and_spawn('committer '    , attribs, 1),
        'committer_date - author_date (seconds)',
        'commit tag',
        'message',
        'message length',
        'file changes',
        'line changes',
        cat_and_spawn('file', [''], 100),
        cat_and_spawn('signed_off_by ', email, 8),
        cat_and_spawn('reported_by '  , email, 8),
        cat_and_spawn('reviewed_by '  , email, 8),
        cat_and_spawn('tested_by '    , email, 8),
        cat_and_spawn('acked_by '     , email, 8),
        cat_and_spawn('cc '           , email, 8)
      ].flatten
    end
  end
end
