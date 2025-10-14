#!/usr/bin/env python3

class BPAsset:
    def __init__(self):
        self._resource = dict()
        self._resource["themelib"] = '''
[
	{
		"Label": "* Fashion *",
		"Config": "/BP Wallpaper/#nd#|/BP Wallpaper/#sn#|/BP Wallpaper/People;Candice Swanepoel|Ekaterina Krarup Andersen|Hannah Ferguson|Irina Shayk|Jessica Gomes|Miranda Kerr|Ratajkowski;"
	},
	{
		"Label": "* Game of Thrones",
		"Config": "/BP Wallpaper/TVShow;Game Of Thrones;"
	},
	{
		"Label": "* Hollywood *",
		"Config": "/BP Wallpaper/#sn#|/BP Wallpaper/Movies|/BP Wallpaper/People;Anya Taylor|Armas|Emma Stone|Gadot|Johansson|Margot|Olsen|Seyfried|Sophie Turner;#nd#"
	},
	{
		"Label": "* Movies + *",
		"Config": "/BP Wallpaper/Animations|/BP Wallpaper/Movies|/BP Wallpaper/TVShow;#nd#|#sn#;"
	},
	{
		"Label": "* People *",
		"Config": "/BP Wallpaper/#nd#|/BP Wallpaper/#sn#|/BP Wallpaper/Games|/BP Wallpaper/People|/BP Wallpaper/Performance;Itzy,유나|강민경|경리|나연|낸시|브레이브걸스 유정|서지수|설현|손나은|수지|슬기|아이린|아이유|유라|윤아|재경|전소미|전효성|제니|지수, 블랙핑크|쯔위|크리스탈|태연|현아;#nd#|#sn#|나인뮤지스, 현아|신수지"
	},
	{
		"Label": "2016-2019",
		"Config": "/BP Photo/2016|/BP Photo/2017|/BP Photo/2017|/BP Photo/2019;;"
	},
	{
		"Label": "Album Art",
		"Config": "/BP Wallpaper/Performance;Album@;#nd#|#sn#"
	},
	{
		"Label": "Bridge",
		"Config": "/BP Photo|/BP Wallpaper/Architecture|/BP Wallpaper/Korea|/BP Wallpaper/USA;Bridge|다리;#nd#|#sn#|Chelsea"
	},
	{
		"Label": "Course Map",
		"Config": "/BP Photo;course map;#nd#|#sn#"
	},
	{
		"Label": "DCEU",
		"Config": "/BP Wallpaper/Movies|/BP Wallpaper/TVShow;Aquaman|Arrow S|Arrowverse|Batman V|Flash S|Harley Quinn|Justice League|Legends of Tomorrow|Man of Steel|Shazam|Stargirl|Suicide Squad|Supergirl S|Titans S|Wonder Woman 1984|Wonder Woman 2017;#nd#|#sn#"
	},
	{
		"Label": "Ghibli",
		"Config": "/BP Wallpaper/Animations|/BP Wallpaper/Windows;Arrietty|Earthsea|Ghibli|Howl|Kaguya|Kiki|Laputa|Marnie|Mononoke|Nausicaa|On Your Mark|Only Yesterday|Ponyo|Poppy Hill|Porco|Red Turtle|Spirited|Totoro|Whisper of|Wind Rises;#nd#|#sn#"
	},
	{
		"Label": "K-Pop",
		"Config": "/BP Wallpaper/Games|/BP Wallpaper/People|/BP Wallpaper/Performance;Exid,하니|Itzy,유나|강민경|경리|나연|낸시|브레이브걸스 유정|서지수|설현|손나은|수지|슬기|아이린|아이유|에스파, 카리나|유라|윤아|재경|전소미|전효성|제니|지수, 블랙핑크|쯔위|크리스탈|태연|현아;#nd#|#sn#|나인뮤지스, 현아|신수지"
	},
	{
		"Label": "Koinari",
		"Config": "/BP Photo/1990|/BP Photo/1991|/BP Photo/1992|/BP Photo/1993|/BP Photo/1994|/BP Photo/1995|/BP Photo/1996;;#nd#|#sn#"
	},
	{
		"Label": "MCU",
		"Config": "/BP Wallpaper/Animations|/BP Wallpaper/Movies|/BP Wallpaper/TVShow;Age of Ultron|Ant-Man|Avengers 2012|Avengers Endgame|Avengers Infinity|Black Panther|Black Widow|Captain America|Cloak|DareDevil S|Doctor Strange|Eternals|Far from Home|Guardians of|Hawkeye|Homecoming|Incredible Hulk|Inhumans|Iron Fist|Iron Man|Jessica Jones|Loki 2021|Luke Cage|Marvel|Moon Knight|No Way Home|Punisher S|Runaways|Shang-Chi|The Falcon|Thor |Wandavision|What If;#nd#|#sn#|Confidential|Lego"
	},
	{
		"Label": "Museum",
		"Config": "/BP Photo/|/BP Wallpaper/Architecture|/BP Wallpaper/Arts;Alte Pinakothek|Belvedere|Galleria|Gallery|Hermitage|Louvre|MOMA|Museo|Museum|Musée|Orsay|Pompidou|Prado|The Met|Uffizi|갤러리|미술관|박물관;#nd#|#sn#"
	},
	{
		"Label": "National Park",
		"Config": "/BP Photo|/BP Wallpaper/Korea|/BP Wallpaper/Landscapes|/BP Wallpaper/Nature|/BP Wallpaper/USA; NP | SP |National Park|Preserve|State Park|forest|국립공원;#nd#|#sn#"
	},
	{
		"Label": "Pixar",
		"Config": "/BP Wallpaper/Animations;Brave|Bug|Cars|Coco|Finding |Good Dino|Incredibles|Inside Out|Monsters|Onward 2020|Ratatouille|Soul 2020|Toy Story|Up Pixar|Wall-E;#nd#|#sn#"
	},
	{
		"Label": "Recent Movie",
		"Config": "/BP Wallpaper/Animations|/BP Wallpaper/Movies|/BP Wallpaper/TVShow;2020|2021|2022;#nd#|#sn#"
	},
	{
		"Label": "Recent TV",
		"Config": "/BP Wallpaper/TVShow;Blindspot|Cloak \u0026 Dagger|Good Place|Hawkeye 2021|Loki|Mandalorian|Queen's Gambit|Stargirl|The Falcon|Wandavision|Westworld|What if|나의 아저씨;#nd#|#sn#"
	},
	{
		"Label": "Religious",
		"Config": "/;Cathedral|Church|Mosque|Sistine|Temple|낙산사|화엄사;#nd#|#sn#"
	},
	{
		"Label": "Scan",
		"Config": "/BP Photo/1990|/BP Photo/1991|/BP Photo/1992|/BP Photo/1993|/BP Photo/1994|/BP Photo/1995|/BP Photo/1996|/BP Photo/1997|/BP Photo/1998|/BP Photo/1999|/BP Photo/2000;;#nd#|#sn#"
	},
	{
		"Label": "Star Wars",
		"Config": "/BP Wallpaper/Animations|/BP Wallpaper/Movies|/BP Wallpaper/TVShow;Boba Fett|Clone Wars|Mandalorian|Star Wars;#nd#|#sn#"
	},
	{
		"Label": "World Wonder",
		"Config": "/BP Photo|/BP Wallpaper/Architecture|/BP Wallpaper/USA;Acropolis|Alhambra|Angkor Wat|Borobudur|Chichen Itza|Christ The Redeemer|Colosseo, Rome|Eiffel Tower|Giza|Great Wall|Hagia Sophia|Kiyomizu|Machu|Moai|Neuschwanstein|Petra|Red Square|Shwe Dagon|Sistine|Statue of Liberty, New|Stonehenge|Sun, Teotihuacan|Sydney Opera|Taj Mahal|Timbuktu;#nd#|#sn#"
	}
]
'''

        self._resource["reservedword"] = '''
[
	{
		"Word": "#nd#",
		"WordPath": ""
	},
	{
		"Word": "#sn#",
		"WordPath": ""
	},
	{
		"Word": "/",
		"WordPath": "/"
	},
	{
		"Word": "/#nd#/",
		"WordPath": "/BP Wallpaper/#nd#"
	},
	{
		"Word": "/#sn#/",
		"WordPath": "/BP Wallpaper/#sn#"
	},
	{
		"Word": "/1971 #sn#/",
		"WordPath": "/BP Photo/1971 #sn#"
	},
	{
		"Word": "/1990/",
		"WordPath": "/BP Photo/1990"
	},
	{
		"Word": "/1991/",
		"WordPath": "/BP Photo/1991"
	},
	{
		"Word": "/1992/",
		"WordPath": "/BP Photo/1992"
	},
	{
		"Word": "/1993/",
		"WordPath": "/BP Photo/1993"
	},
	{
		"Word": "/1994/",
		"WordPath": "/BP Photo/1994"
	},
	{
		"Word": "/1995/",
		"WordPath": "/BP Photo/1995"
	},
	{
		"Word": "/1996/",
		"WordPath": "/BP Photo/1996"
	},
	{
		"Word": "/1997/",
		"WordPath": "/BP Photo/1997"
	},
	{
		"Word": "/1998/",
		"WordPath": "/BP Photo/1998"
	},
	{
		"Word": "/1999/",
		"WordPath": "/BP Photo/1999"
	},
	{
		"Word": "/2000/",
		"WordPath": "/BP Photo/2000"
	},
	{
		"Word": "/2001/",
		"WordPath": "/BP Photo/2001"
	},
	{
		"Word": "/2002/",
		"WordPath": "/BP Photo/2002"
	},
	{
		"Word": "/2003/",
		"WordPath": "/BP Photo/2003"
	},
	{
		"Word": "/2004/",
		"WordPath": "/BP Photo/2004"
	},
	{
		"Word": "/2005/",
		"WordPath": "/BP Photo/2005"
	},
	{
		"Word": "/2006/",
		"WordPath": "/BP Photo/2006"
	},
	{
		"Word": "/2007/",
		"WordPath": "/BP Photo/2007"
	},
	{
		"Word": "/2008/",
		"WordPath": "/BP Photo/2008"
	},
	{
		"Word": "/2009/",
		"WordPath": "/BP Photo/2009"
	},
	{
		"Word": "/2010/",
		"WordPath": "/BP Photo/2010"
	},
	{
		"Word": "/2011/",
		"WordPath": "/BP Photo/2011"
	},
	{
		"Word": "/2012/",
		"WordPath": "/BP Photo/2012"
	},
	{
		"Word": "/2013/",
		"WordPath": "/BP Photo/2013"
	},
	{
		"Word": "/2014/",
		"WordPath": "/BP Photo/2014"
	},
	{
		"Word": "/2015/",
		"WordPath": "/BP Photo/2015"
	},
	{
		"Word": "/2016/",
		"WordPath": "/BP Photo/2016"
	},
	{
		"Word": "/2017/",
		"WordPath": "/BP Photo/2017"
	},
	{
		"Word": "/2018/",
		"WordPath": "/BP Photo/2018"
	},
	{
		"Word": "/2019/",
		"WordPath": "/BP Photo/2019"
	},
	{
		"Word": "/2020/",
		"WordPath": "/BP Photo/2020"
	},
	{
		"Word": "/2021/",
		"WordPath": "/BP Photo/2021"
	},
	{
		"Word": "/2022/",
		"WordPath": "/BP Photo/2022"
	},
	{
		"Word": "/Animations/",
		"WordPath": "/BP Wallpaper/Animations"
	},
	{
		"Word": "/Anime/",
		"WordPath": "/BP Wallpaper/Anime"
	},
	{
		"Word": "/Architecture/",
		"WordPath": "/BP Wallpaper/Architecture"
	},
	{
		"Word": "/Arts/",
		"WordPath": "/BP Wallpaper/Arts"
	},
	{
		"Word": "/BP Photo/",
		"WordPath": "/BP Photo"
	},
	{
		"Word": "/BP Wallpaper/",
		"WordPath": "/BP Wallpaper"
	},
	{
		"Word": "/Cars/",
		"WordPath": "/BP Wallpaper/Cars"
	},
	{
		"Word": "/ETC/",
		"WordPath": "/BP Wallpaper/ETC"
	},
	{
		"Word": "/Games/",
		"WordPath": "/BP Wallpaper/Games"
	},
	{
		"Word": "/Korea/",
		"WordPath": "/BP Wallpaper/Korea"
	},
	{
		"Word": "/Landscapes/",
		"WordPath": "/BP Wallpaper/Landscapes"
	},
	{
		"Word": "/Life/",
		"WordPath": "/BP Wallpaper/Life"
	},
	{
		"Word": "/Movies/",
		"WordPath": "/BP Wallpaper/Movies"
	},
	{
		"Word": "/Nature/",
		"WordPath": "/BP Wallpaper/Nature"
	},
	{
		"Word": "/People/",
		"WordPath": "/BP Wallpaper/People"
	},
	{
		"Word": "/Performance/",
		"WordPath": "/BP Wallpaper/Performance"
	},
	{
		"Word": "/Space/",
		"WordPath": "/BP Wallpaper/Space"
	},
	{
		"Word": "/TVShow/",
		"WordPath": "/BP Wallpaper/TVShow"
	},
	{
		"Word": "/USA/",
		"WordPath": "/BP Wallpaper/USA"
	},
	{
		"Word": "/Windows/",
		"WordPath": "/BP Wallpaper/Windows"
	}
]
'''

'''
asset = BPAsset()
print(asset._resource["themelib"])
print(asset._resource["reservedword"])
'''