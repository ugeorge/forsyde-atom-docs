#!/bin/python

from lxml.html import parse, Element
import sys
reload(sys)
sys.setdefaultencoding('utf-8')


tree = parse(sys.stdin)

for tag in tree.xpath('//em'):
    string = tag.text
    if string:
        tag.text = "\\emph{"+ string +"}"

# for tag in tree.xpath('//code'):
#     string = tag.text
#     if string:
#         tag.text = "\\haddockid{"+ string +"}"
#         print tag.text

for tag in tree.xpath('//code/a'):
    string = tag.text
    if string:
        tag.text = "\\haddockid{"+ string +"}"

for tag in tree.xpath('//p[@class=\'src\']/a[@class=\'def\']'):
    string = tag.text
    if string:
        tag.text = "\\haddockid{"+ string +"}"

for tag in tree.xpath('//img'):
    string = tag.attrib['src']
    if string:
        tag.getparent().text = "(image : " + string + " )"

# for tag in tree.findall('//p'):
#     string = tag.text
#     if string:
#         tag.text = string + "\\n"

path='/html/body/div[@id=\'content\']/div[@id=\'interface\']/div[@class=\'top\']/div[@class=\'subs methods\']/div[@class=\'doc\']'
for tag in tree.xpath(path):
    newelem = Element("p")
    newelem.text = "#"
    tag.append(newelem)

    path='/html/body/div[@id=\'content\']/div[@id=\'interface\']/div[@class=\'top\']/div[@class=\'subs methods\']/p[@class=\'src\']/text()' \
+'|/html/body/div[@id=\'content\']/div[@id=\'interface\']/div[@class=\'top\']/div[@class=\'subs methods\']/p[@class=\'src\']/a/text()'
methodN = tree.xpath(path)

methods = ''.join(str(v) for v in methodN).split("#")
methods = [x for x in methods if x is not '']


path='/html/body/div[@id=\'content\']/div[@id=\'interface\']/div[@class=\'top\']/div[@class=\'subs methods\']/div[@class=\'doc\']/p/text()'\
+'|/html/body/div[@id=\'content\']/div[@id=\'interface\']/div[@class=\'top\']/div[@class=\'subs methods\']/div[@class=\'doc\']/p//text()'

docsN = tree.xpath(path)

docs = ''.join(str(v) for v in docsN).replace('\n', ' ').split("#")
docs = [x for x in docs if x is not '']


#########################################

path='/html/body/div[@id=\'content\']/div[@id=\'interface\']/div[@class=\'top\']/div[@class=\'subs associated-types\']/p[@class=\'src\']/text()' \
+'|/html/body/div[@id=\'content\']/div[@id=\'interface\']/div[@class=\'top\']/div[@class=\'subs associated-types\']/p[@class=\'src\']/a/text()'
familyN = tree.xpath(path)

families = ''.join(str(v) for v in familyN).split("#")
families = [x for x in families if x is not '']

path='/html/body/div[@id=\'content\']/div[@id=\'interface\']/div[@class=\'top\']/div[@class=\'subs associated-types\']/div[@class=\'doc\']'
for tag in tree.xpath(path):
    newelem = Element("p")
    newelem.text = "#"
    tag.append(newelem)

path='/html/body/div[@id=\'content\']/div[@id=\'interface\']/div[@class=\'top\']/div[@class=\'subs associated-types\']/div[@class=\'doc\']/p/text()'\
+'|/html/body/div[@id=\'content\']/div[@id=\'interface\']/div[@class=\'top\']/div[@class=\'subs associated-types\']/div[@class=\'doc\']/p//text()'

famdocsN = tree.xpath(path)

famdocs = ''.join(str(v) for v in famdocsN).replace('\n', ' ').split("#")
famdocs = [x for x in famdocs if x is not '']

output= zip (families, famdocs) + zip (methods, docs)

# print methods

print output
