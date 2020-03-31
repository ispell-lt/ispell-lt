#!/usr/bin/env python3
"""
Priemonës þodþiø ieðkoti VDU KLC tekstyne per webiná interfeisà.

$Id: donelaitis.py,v 1.1 2003/06/11 10:06:48 alga Exp $
"""
import urllib
import re
import ispell
import sys

def parseTable(html):
    tag = re.compile('<.*?>')
    td  = re.compile('<td .*?>')
    tr  = re.compile('<tr .*?>')

    html = td.sub('<td>', html)
    html = tr.sub('<tr>', html)

    table = html[html.find('<table'):html.find('</table')]
    row_index = table.find('<tr')
    rows = table.split('<tr>')[1:]
    table = ()
    for row in rows:
        cols = row.split('<td>')[1:]
        result = ()
        for col in  cols:
            col = tag.sub('', col)
            col = col.strip()
            result += (col,)
        table += (result,)
    return table

class CorpusWord:

    def __init__(self, word, prefetch=True):
        self.word = word
        self.url = \
                 "http://donelaitis.vdu.lt/cgi-bin/find2.cgi?a=%s&kontek=&l=2"
        self.html = None
        if prefetch:
            self.fetch()

    def fetch(self):
        """Atsisiunèia ir iðlukðtena tekstyno duomenis"""
        if self.html is None:
            self.html = urllib.urlopen(self.url % self.word).read()
        self.data = parseTable(self.html)

    def totalMatches(self):
        """Gràþina kiek viso þodþio pasirodymø yra tekstyne"""
        result = 0
        for row in self.data:
            try:
                result += int(row[1])
            except ValueError:
                pass
        return result


def sortWords(dict=None, all_forms=False):
    """Visus þodþius ið þodyno ieðkom tekstyne ir spausdinam su
    pasitaikymø daþniais."""

    # XXX: Unit tests!

    if dict is None:
        dict = open(sys.argv[1])

    results = []
    for line in dict.readlines():

        line = line.strip()
        word = ispell.splitEntry(line)[0]

        if all_forms:
            words = ispell.expand(line)
        else:
            words = [word]

        for word in words:
            if word:
                print word,
                w = CorpusWord(word)
                c = w.totalMatches()
                results.append((c, word))

    results.sort()
    return ["%d\t%s" % (c, w) for c, w in results]

if __name__ == '__main__':
    print "\n".join(sortWords())
