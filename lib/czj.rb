class CZJDict < Object
  #attr_accessor :servlet
  attr_accessor :dictcode
  attr_accessor :write_dicts
  attr_accessor :sign_dicts
  attr_accessor :dict_info

  def initialize(dictcode)
    @dictcode = dictcode 
    #@servlet = CZJServlet
    @collection = $mongo[dictcode]
    @entrydb = $mongo['entries']
  end

  def getdoc(id)
    $stderr.puts id
    $stderr.puts @dictcode

    data = @entrydb.find({'id': id, 'dict': @dictcode}).first
    $stderr.puts data
    entry = full_entry(data)
    entry = add_rels(entry)
    return entry
  end

  def full_entry(entry, getsw=true)
    entry = add_media(entry)
    entry = add_colloc(entry) if getsw
    entry = get_sw(entry) if getsw
    return entry
  end

  def add_colloc(entry)
    entry['revcollocations'] = {} if entry['revcollocations'].nil?
    entry['revcollocations']['entries'] = []
    if @write_dicts.include?(entry['dict'])
      locale = entry['dict']
      locale = 'sk' if entry['dict'] == 'sj'
      collate = {:collation => {'locale' => locale}, :sort => {'lemma.title' => 1}}
    else
      collate = { :sort => {'id'=>1}}
    end

    @entrydb.find({'dict': entry['dict'], 'collocations.colloc': entry['id'], 'lemma.lemma_type': 'collocation'}, collate).each{|ce|
      ce = add_media(ce)
      ce = get_sw(ce)
      entry['revcollocations']['entries'] << ce
    }

    if entry['collocations'] and entry['collocations']['colloc']
      entry['collocations']['entries'] = []
      entry['collocations']['colloc'].uniq.each{|coll|
        ce = @entrydb.find({'dict': entry['dict'], 'id': coll}).first
        unless ce.nil?
          ce = add_colloc(ce)
          ce = get_sw(ce)
          entry['collocations']['entries'] << ce
        end
      }
    end
    return entry
  end

  def get_sw(entry)
    $stderr.puts 'GETSW'
    swdoc = $mongo['sw'].find({'id': entry['id'], 'dict': entry['dict']})
    $stderr.puts swdoc.first
    if swdoc.first
      entry['lemma']['swmix'] = swdoc.first['swmix']
    else
      entries_used = [entry['id']]
      entry['lemma']['swmix'] = []
      if ['collocation','derivat','kompozitum','fingerspell'].include?(entry['lemma']['lemma_type'])
        if entry['collocations']
          # spojeni
          if entry['collocations']['swcompos'].to_s == ''
            # prazdne SW compos
            if entry['lemma']['lemma_type'] == 'derivat' or entry['lemma']['lemma_type'] == 'kompozitum'
              # derivat/komp = zustava hlavni SW
              entry['lemma']['swmix'] = entry['lemma']['sw'].dup
            else
              # spojeni/spell = SW casti
              if entry['collocations']['entries']
                entry['collocations']['entries'].each{|ce|
                  entries_used << ce['id']
                  if ce['lemma'] and ce['lemma']['swmix']
                    ce['lemma']['swmix'].each{|swc| entry['lemma']['swmix'] << swc.dup}
                  end
                }
              end
            end
          else
            #vyplnene SW compos
            entry['collocations']['swcompos'].split(',').each{|swid|
              swid.strip!
              $stderr.puts 'sw part '+swid
              if swid[0,2].upcase == 'SW'
                #copy from this entry
                swn = swid[2..-1].to_i-1
                entry['lemma']['swmix'] << entry['lemma']['sw'][swn].dup unless entry['lemma']['sw'][swn].nil?
              elsif swid.upcase =~ /^[A-Z]$/
                #copy from this entry
                $stderr.puts 'get SW char from this entry ' + swid + ' = ' + (swid[0].ord-65).to_s
                swn = swid[0].ord-65
                entry['lemma']['swmix'] << entry['lemma']['sw'][swn].dup unless entry['lemma']['sw'][swn].nil?
              else
                # copy from part
                if swid.upcase =~ /[A-Z]/
                  # copy one char
                  match = /([0-9]+)([A-Z]+)/.match(swid.upcase)
                  unless match.nil?
                    $stderr.puts 'copy char '+swid+' ('+(match[1].to_i-1).to_s+':'+(match[2][0].ord-65).to_s+')'
                    if entry['collocations'] and entry['collocations']['entries']
                      unless entry['collocations']['entries'][match[1].to_i-1].nil?
                        unless entry['collocations']['entries'][match[1].to_i-1]['lemma']['sw'].first.nil?
                          entries_used << entry['collocations']['entries'][match[1].to_i-1]['id']
                          entry['lemma']['swmix'] << entry['collocations']['entries'][match[1].to_i-1]['lemma']['sw'][match[2][0].ord-65].dup unless entry['collocations']['entries'][match[1].to_i-1]['lemma']['sw'][match[2][0].ord-65].nil?
                        else
                          entries_used << entry['collocations']['entries'][match[1].to_i-1]['id']
                          entry['lemma']['swmix'] << entry['collocations']['entries'][match[1].to_i-1]['lemma']['swmix'][match[2][0].ord-65].dup unless entry['collocations']['entries'][match[1].to_i-1]['lemma']['swmix'][match[2][0].ord-65].nil?
                        end
                      end
                    end
                  end
                else
                  # copy full
                  $stderr.puts 'copy full '+swid
                  if entry['collocations'] and entry['collocations']['entries']
                    unless entry['collocations']['entries'][swid.to_i-1].nil?
                      if entry['collocations']['entries'][swid.to_i-1]['lemma']['swmix'].nil? or entry['collocations']['entries'][swid.to_i-1]['lemma']['swmix'].size == 0
                        entries_used << entry['collocations']['entries'][swid.to_i-1]['id']
                        entry['collocations']['entries'][swid.to_i-1]['lemma']['sw'].each{|swel|
                          entry['lemma']['swmix'] << swel.dup
                        }
                      else
                        entries_used << entry['collocations']['entries'][swid.to_i-1]['id']
                        entry['collocations']['entries'][swid.to_i-1]['lemma']['swmix'].each{|swel|
                          entry['lemma']['swmix'] << swel.dup
                        }
                      end
                    end
                  end
                end
              end
            }
          end
        end
      else
        # jednoduche
        if entry['lemma']['sw']
          if entry['lemma']['sw'].find{|sw| sw['@primary'] == 'true'}
            # primary SW
            entry['lemma']['swmix'] = entry['lemma']['sw'].select{|sw| sw['@primary'] == 'true'}
          else
            # no primary SW
            entry['lemma']['swmix'] = entry['lemma']['sw'].dup
          end
        end
      end
      $mongo['sw'].insert_one({'id': entry['id'], 'dict': entry['dict'], 'swmix': entry['lemma']['swmix'], 'entries_used': entries_used})
    end
    return entry
  end

  def get_media(media_id, dict)
    media = $mongo['media'].find({'id': media_id, 'dict': dict})
    if media.first
      media_info = media.first
      entries = $mongo['entries'].find({'dict': dict, 'lemma.video_front': media_info['location']})
      if entries.first
        media_info['main_for_entry'] = entries.first
      end
      return media_info
    else
      return {}
    end
  end
  def get_media_location(media_id, dict)
    media = $mongo['media'].find({'location': media_id, 'dict': dict})
    if media.first
      return media.first
    else
      return {}
    end
  end

  def add_media(entry, main_only=false)
    entry['media'] = {}
    if not main_only
      if entry['meanings']
        entry['meanings'].each{|mean|
          entry['media'][mean['text']['file']['@media_id']] = get_media(mean['text']['file']['@media_id'], entry['dict']) if mean['text'] and mean['text']['file']
          mean['usages'].each{|usg|
            entry['media'][usg['text']['file']['@media_id']] = get_media(usg['text']['file']['@media_id'], entry['dict']) if usg['text'] and usg['text']['file']
          }
        }
      end
      if entry['lemma']['grammar_note']
        entry['lemma']['grammar_note'].each{|gn|
          if gn['variant']
            gn['variant'].each{|gv|
              entry['media'][gv['_text']] = get_media(gv['_text'], entry['dict']) if gv['_text'] != ''
            }
          end
          if gn['_text'] and gn['_text'] =~ /media_id/
            gn['_text'].scan(/\[media_id=([0-9]+)\]/).each{|gm|
              entry['media'][gm[0]] = get_media(gm[0], entry['dict'])
            }
          end
        }
      end
      if entry['lemma']['style_note']
        entry['lemma']['style_note'].each{|gn|
          if gn['variant']
            gn['variant'].each{|gv|
              entry['media'][gv['_text']] = get_media(gv['_text'], entry['dict']) if gv['_text'] != ''
            }
          end
          if gn['_text'] and gn['_text'] =~ /media_id/
            gn['_text'].scan(/\[media_id=([0-9]+)\]/).each{|gm|
              entry['media'][gm[0]] = get_media(gm[0], entry['dict'])
            }
          end
        }
      end
    end
    if entry['lemma']['video_front'].to_s != ''
      entry['media']['video_front'] = get_media_location(entry['lemma']['video_front'].to_s, entry['dict'])
    end
    if entry['lemma']['video_side'].to_s != ''
      entry['media']['video_side'] = get_media_location(entry['lemma']['video_side'].to_s, entry['dict'])
    end
    return entry
  end

  def add_rels(entry, getsw=true, type=nil, target=nil)
    entry['meanings'].each{|mean|
      if mean['relation']
        mean['relation'].each{|rel|
          next if type != nil and rel['type'] != type
          next if target != nil and rel['target'] != target
          if rel['meaning_id'] =~ /^[0-9]*-[0-9]*$/
            rela = rel['meaning_id'].split('-')
            lemmaid = rela[0]
            rel['meaning_nr'] = rela[1]
            relentry = @entrydb.find({'dict': rel['target'], 'id': lemmaid}).first
            next if relentry.nil?
            relentry = add_colloc(relentry) if getsw
            relentry = get_sw(relentry) if getsw
            relentry = add_media(relentry, true)
            rel['entry'] = relentry
          elsif rel['meaning_id'] =~ /^[0-9]*-[0-9]*_us[0-9]*$/
            rela = rel['meaning_id'].split('-')
            lemmaid = rela[0]
            relentry = @entrydb.find({'dict': rel['target'], 'id': lemmaid}).first
            next if relentry.nil?
            rel['entry'] = relentry
            if rel['entry']
              rel['entry']['meanings'].each{|rm|
                if rm['usages']
                  rm['usages'].each{|ru|
                    if ru['id'] == rel['meaning_id']
                      rel['entry']['lemma']['title'] = ru['text']['_text']
                    end
                  }
                end
              }
            end
          else
            rel['entry'] = {'lemma'=>{'title'=>rel['meaning_id']}}
            rel['meaning_nr'] = ''
          end
        }
      end
      if mean['text'] and mean['text']['_text']
        mean['text']['_text'].scan(/\[([0-9]+)(-[0-9]+)?\]/).each{|mrel|
          relid = mrel[0]
          mean['def_relations'] = {} if mean['def_relations'].nil?
          mean['def_relations'][relid] = @entrydb.find({'dict': entry['dict'], 'id': relid}).first['lemma']['title']
        }
      end
    }
    return entry
  end

  def get_key_search(search)
      search_ar = search.split('|')
      search_shape = search_ar[0].to_s.split(',') #tvary
      search_jedno = []
      search_obe_ruzne = []
      search_obe_stejne = []
      $stderr.puts search_shape
      search_shape.each{|e|
        #jednorucni, rotace jen 0-7
        search_jedno << {
          'lemma.sw'=>{
            '$elemMatch'=>{
              '$and'=>[
                {'@fsw'=>{'$regex'=>e+'[0-5][0-7]'}},
                {'@fsw'=>{'$not'=>{'$regex'=>'S1[0-9a-f][0-9a-f][0-5][89a-f]'}}},
                {'@fsw'=>{'$not'=>{'$regex'=>'S20[0-4][0-5][89a-f]'}}}
              ]
            }
          }
        }
        #dve ruce, stejne rotace 0-7 + 8-f
        search_obe_stejne << {
          'lemma.sw'=>{
            '$elemMatch'=>{
              '$and'=>[
                {'@fsw'=>{'$regex'=>e+'[0-5][0-7]'}},
                {'@fsw'=>{'$regex'=>e+'[0-5][89a-f]'}},
              ]
            }
          }
        }
        #dve ruce, ruzne, hledana 0-7 a jina 8-f, nebo hledana 8-f a jina 0-7
        search_obe_ruzne << {
          'lemma.sw'=>{
            '$elemMatch'=>{
              '$or'=>[
                {
                  '$and'=>[
                    {'@fsw'=>{'$regex'=>e+'[0-5][0-7]'}},
                    {'@fsw'=>{'$not'=>{'$regex'=>e+'[0-5][89a-f]'}}},
                    {'$or'=>[
                      {'@fsw'=>{'$regex'=>'S1[0-9a-f][0-9a-f][0-5][89a-f]'}},
                      {'@fsw'=>{'$regex'=>'S20[0-4][0-5][89a-f]'}},
                    ]
                    }
                  ]
                },
                {
                  '$and'=>[
                    {'@fsw'=>{'$regex'=>e+'[0-5][89a-f]'}},
                    {'@fsw'=>{'$not'=>{'$regex'=>e+'[0-5][0-7]'}}},
                    {'$or'=>[
                      {'@fsw'=>{'$regex'=>'S1[0-9a-f][0-9a-f][0-5][0-7]'}},
                      {'@fsw'=>{'$regex'=>'S20[0-4][0-5][0-7]'}},
                    ]
                    }
                  ]
                },
              ]
            }
          }
        }
      }

      if search_ar[1].to_s != ''
        #pridame umisteni
        search_loc = search_ar[1].split(',')
        search_jedno.map!{|e| 
          e['lemma.sw']['$elemMatch']['@misto'] = {'$in'=>search_loc}
          e
        }
        search_obe_stejne.map!{|e| 
          e['lemma.sw']['$elemMatch']['@misto'] = {'$in'=>search_loc}
          e
        }
        search_obe_ruzne.map!{|e| 
          e['lemma.sw']['$elemMatch']['@misto'] = {'$in'=>search_loc}
          e
        }
        if search_jedno.length == 0
          search_jedno << {'lemma.sw'=>{'$elemMatch'=>{'@misto'=>{'$in'=>search_loc}}}}
        end
        if search_obe_ruzne.length == 0
          search_obe_ruzne << {'lemma.sw'=>{'$elemMatch'=>{'@misto'=>{'$in'=>search_loc}}}}
        end
        if search_obe_stejne.length == 0
          search_obe_stejne << {'lemma.sw'=>{'$elemMatch'=>{'@misto'=>{'$in'=>search_loc}}}}
        end
      end

      # dvourucni volby, vyber dotazu
      if search_ar[2].to_s != ''
        search_two = search_ar[2].split(',')
        if search_two.include?('sym')
          search_query = search_obe_stejne
        else
          search_query = search_obe_ruzne
        end
        if search_two.include?('act')
          search_query.map!{|e| 
            e['lemma.sw']['$elemMatch']['$and'] = [] if e['lemma.sw']['$elemMatch']['$and'].nil?
            e['lemma.sw']['$elemMatch']['$and'] << {
              '$or'=>[
                {'@fsw'=>{'$regex'=>'S2[2-9a-f][0-9a-f]2'}},
                {'$and'=>[
                  {'@fsw'=>{'$regex'=>'S2[2-9a-f][0-9a-f]0'}},
                  {'@fsw'=>{'$regex'=>'S2[2-9a-f][0-9a-f]1'}},
                ]
                },
                {'$and'=>[
                  {'@fsw'=>{'$not'=>{'$regex'=>'S2[2-9a-f][0-9a-f]'}}},
                  {'$or'=>[
                    {'@fsw'=>{'$regex'=>'S20[567bcd]'}},
                    {'@fsw'=>{'$regex'=>'S21[123]'}},
                  ]}
                ]
                }
              ]
            }
            e
          }
        end
      else 
        search_query = search_jedno
      end
      return search_query
  end

  def search(dictcode, search, type, start=0, limit=nil)
    res = []
    resultcount = 0
    case type
    when 'text'
      search = search.downcase
      if search =~ /^[0-9]*$/
        @entrydb.find({'dict': dictcode, 'id': search}).each{|re|
          res << full_entry(re)
          resultcount = 1
        }
      elsif search == '*'
        @entrydb.find({'dict': dictcode}).each{|re|
          res << re
        }
      else
        if @write_dicts.include?(dictcode)
          fullids = []
          locale = dictcode
          locale = 'sk' if dictcode == 'sj'
          search_cond = {'dict': dictcode, '$or': [{'lemma.title': search}, {'lemma.title_var': search}]}
          search_cond[:$or] << {'lemma.title_dia': search} 
          search_cond[:$or] << {'lemma.gram.form._text': search} 
          cursor = @entrydb.find(search_cond, :sort => {'lemma.title'=>1})
          fullcount = cursor.count_documents
          cursor.each{|re|
            res << re if fullcount > start
            fullids << re['id']
          }
          search_cond = {'dict': dictcode, 'id': {'$nin': fullids}, '$or': [{'lemma.title': {'$regex': /^#{search}/}}]}
          search_cond[:$or] << {'lemma.title': {'$regex': /(^| )#{search}/}}
          start = start - fullcount if start > 0
          cursor = @entrydb.find(search_cond, {:collation => {'locale'=>locale}, :sort => {'lemma.title'=>1}})
          resultcount = fullcount + cursor.count_documents
          cursor = cursor.skip(start)
          if limit.to_i > 0
            limit = limit - fullcount if fullcount > start
            cursor = cursor.limit(limit)
          end
          $stderr.puts 'START='+start.to_s
          $stderr.puts 'LIMIT='+limit.to_s
          
          cursor.each{|re|
            res << re #full_entry(re)
          }
        else
          search_in = 'cs'
          search_in = @dict_info[dictcode]['search_in'] unless @dict_info[dictcode]['search_in'].nil?
          csl = [search]
          $mongo['entries'].find({'dict'=>search_in, 'lemma.title'=> search}, {'projection'=>{'meanings.id'=>1, '_id'=>0}}).each{|re|
            unless re['meanings'].nil?
              re['meanings'].each{|rl| 
                csl << rl['id']
              }
            end
          }
          cursor = $mongo['entries'].find({'dict'=>dictcode, 'meanings.relation'=>{'$elemMatch'=>{'target'=>search_in,'meaning_id'=>{'$in'=>csl}}}})
          resultcount = cursor.count_documents
          cursor = cursor.skip(start)
          cursor = cursor.limit(limit) if limit.to_i > 0
          cursor.each{|e|
            res << full_entry(e, false)
          }
        end
      end
    when 'key'
      search_query = {'dict'=>dictcode, '$or'=>get_key_search(search)}
      $stderr.puts search_query
      cursor = $mongo['entries'].find(search_query)
      resultcount = cursor.count_documents
      cursor = cursor.skip(start)
      cursor = cursor.limit(limit) if limit.to_i > 0
      cursor.each{|e|
        res << add_media(e, true)
      }
    end
    return {'count'=> resultcount, 'entries'=> res}
  end

  def translate2(source, target, search, type, start=0, limit=nil)
    res = []
    resultcount = 0
    case type
    when 'text'
      search = search.downcase
      if search =~ /^[0-9]*$/
        @entrydb.find({'dict': dictcode, 'id': search}).each{|re|
          res << full_entry(re)
          resultcount = 1
        }
      else
        if @write_dicts.include?(source)
          locale = source
          locale = 'sk' if source == 'sj'
          search_cond_text = {'$or': []}
          search_cond_text[:$or] << {'lemma.title': search} 
          search_cond_text[:$or] << {'lemma.title_var': search} 
          search_cond_text[:$or] << {'lemma.title_dia': search} 
          search_cond_text[:$or] << {'lemma.gram.form._text': search} 
          search_cond_text[:$or] << {'lemma.title': {'$regex': /^#{search}/}}
          search_cond_text[:$or] << {'lemma.title': {'$regex': /(^| )#{search}/}}
          search_cond_rel = {'meanings.relation':{'$elemMatch': {'target': target, 'type': 'translation'}}}
          search_cond = {'dict': dictcode, '$and': [search_cond_text, search_cond_rel]}
          $stderr.puts search_cond
          ## > db.entries.aggregate([{'$match':{dict:"cs", '$and':[{'$or':[{"lemma.title":"bratranec"},{"lemma.title":"bratr"}]}, {"meanings.relation":{'$elemMatch':{target:"czj", type:"translation"}}}]}}, {'$unwind':'$meanings'}, {'$unwind':'$meanings.relation'},{'$match':{'meanings.relation.target':'czj'}},{'$project':{'meanings.relation':1, 'id':1}},{'$limit':2}])
          pipeline = [
            {'$match' => search_cond},
            {'$unwind' => '$meanings'},
            {'$unwind' => '$meanings.relation'},
            {'$match' => {'meanings.relation.target'=>target}},
            {'$sort' => {'lemma.title'=>1}}
          ]
          @entrydb.aggregate(pipeline+[{'$count'=>'total'}]).each{|re|
            resultcount = re['total'].to_i
          }
          pipeline << {'$skip' => start.to_i}
          pipeline << {'$limit' => limit.to_i} if limit.to_i > 0
          cursor = @entrydb.aggregate(pipeline, :allow_disk_use => true)
          cursor.each{|re|
            re['meanings']['relation'] = [re['meanings']['relation']]
            re['meanings'] = [re['meanings']]
            entry = add_rels(re, true, 'translation', target)
            entry = get_sw(entry)
            res << entry
          }
        else
          search_in = 'cs'
          search_in = @dict_info[dictcode]['search_in'] unless @dict_info[dictcode]['search_in'].nil?
          csl = [search]
          $mongo['entries'].find({'dict'=>search_in, 'lemma.title'=> search}, {'projection'=>{'meanings.id'=>1, '_id'=>0}}).each{|re|
            unless re['meanings'].nil?
              re['meanings'].each{|rl| 
                csl << rl['id']
              }
            end
          }
          cursor = $mongo['entries'].find({'dict'=>dictcode, 'meanings.relation'=>{'$elemMatch'=>{'target'=>search_in,'meaning_id'=>{'$in'=>csl}}}})
          resultcount = cursor.count_documents
          cursor = cursor.skip(start)
          cursor = cursor.limit(limit) if limit.to_i > 0
          cursor.each{|e|
            entry = add_rels(e, true, 'translation', target)
            entry = get_sw(entry)
            res << entry
          }
        end
      end
    when 'key'
      search_cond_text = {'$or': get_key_search(search)}
      search_cond_rel = {'meanings.relation':{'$elemMatch': {'target': target, 'type': 'translation'}}}
      search_cond = {'dict': dictcode, '$and': [search_cond_text, search_cond_rel]}
      $stderr.puts search_cond
          pipeline = [
            {'$match' => search_cond},
            {'$unwind' => '$meanings'},
            {'$unwind' => '$meanings.relation'},
            {'$match' => {'meanings.relation.target'=>target}},
          ]
          @entrydb.aggregate(pipeline+[{'$count'=>'total'}]).each{|re|
            resultcount = re['total'].to_i
          }
          pipeline << {'$skip' => start.to_i}
          pipeline << {'$limit' => limit.to_i} if limit.to_i > 0
          cursor = @entrydb.aggregate(pipeline, :allow_disk_use => true)
          cursor.each{|re|
            re['meanings']['relation'] = [re['meanings']['relation']]
            re['meanings'] = [re['meanings']]
            entry = add_rels(re, true, 'translation', target)
            entry = get_sw(entry)
            res << entry
          }
    end
    return {'count'=> resultcount, 'entries'=> res}
  end

  def translate(source, target, search, type, start=0, limit=nil)
    search_res = search(source, search, type)['entries']
    res = []
    relcount = 0
    search_res.select{|entry| 
      if entry['meanings']
        entry['meanings'].find{|mean| 
          mean['relation'].find{|rel| rel['target'] == target}
        }
      end
    }.each{|entry| 
      $stderr.puts entry['id']
      $stderr.puts 'add translation'
      entry = add_rels(entry, true, 'translation', target)
      $stderr.puts 'add syno'
      entry = add_rels(entry, true, 'synonym', source)
      $stderr.puts 'add anto'
      entry = add_rels(entry, true, 'antonym', source)
      entry = get_sw(entry)
      entry['meanings'].each{|mean|
        relcount += mean['relation'].select{|rel| rel['target'] == target}.size
      }
      res << entry
      break if limit.to_i > 0 and relcount > (start + limit + 1)
    }

    #pridat textove preklady, vcetne prekladu v prikladech
    if limit.to_i == 0 or relcount <= (start + limit)
      search_cond = {'dict'=>target, '$or'=>[]}
      search_cond['$or'] << {'meanings.relation'=>{'$elemMatch'=>{'target'=>source,'meaning_id'=>{'$regex'=>/(^| )#{search}/}}}}
      search_cond['$or'] << {'meanings.usages.relation'=>{'$elemMatch'=>{'target'=>source,'meaning_id'=>{'$regex'=>/(^| )#{search}/}}}}
      cursor = $mongo['entries'].find(search_cond)
      cursor.each{|e|
        e['meanings'].each{|mean|
          next if mean['is_translation_unknown'].to_s == '1'
          mean['relation'].each{|rel|
            if rel['target'] == source and rel['meaning_id'].match(/(^| )#{search}/)
              newdoc = {'id'=>nil,'dict'=>source, 'lemma'=>{'title'=>rel['meaning_id']}, 'meanings'=>[{'relation'=>[{'target'=>target, 'meaning_id'=>mean['id'], 'lemma_id'=>e['id'], 'type'=>'translation', 'entry'=>e}]}]}
              res << newdoc
              relcount += 1
            end
          }
          if mean['usages']
            mean['usages'].each{|usg|
              if usg['relation']
                usg['relation'].each{|rel|
                  if rel['target'] == source and rel['meaning_id'].match(/(^| )#{search}/)
                    newdoc = {'id'=>nil,'dict'=>source, 'lemma'=>{'title'=>rel['meaning_id']}, 'meanings'=>[{'relation'=>[{'target'=>target, 'meaning_id'=>usg['id'], 'lemma_id'=>e['id'], 'type'=>'translation', 'entry'=>e}]}]}
                    newdoc['meanings'][0]['relation'][0]['entry']['lemma']['video_front'] = get_media(usg['text']['file']['@media_id'], target)['location'] if usg['text']['file']
                    res << newdoc
                    relcount += 1
                  end
                }
              end
            }
          end
        }
        break if limit.to_i > 0 and relcount > (start + limit + 1)
      }
    end

    # select part of results
    if limit.to_i > 0
      usedrels = 0
      newres = []
      res.each{|entry|
        entry['meanings'].each{|mean|
          rel_to_del = []
          mean['relation'].each{|rel|
            if rel['target'] == target
              rel_to_del << rel['meaning_id'] if usedrels < start
              rel_to_del << rel['meaning_id'] if usedrels >= (start + limit)
              usedrels += 1 
            end
          }
          rel_to_del.each{|rid|
            mean['relation'].delete_if{|rel| rel['target'] == target and rel['meaning_id'] == rid}
          }
        }
        newres << entry
        break if usedrels >= (start + limit)
      }
      res = newres
    end

    return {'count'=> relcount, 'entries'=> res}
  end
end

