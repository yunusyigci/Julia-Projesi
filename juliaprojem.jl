using Plots
using PyPlot
using Clustering
using Requests
using StatPlots
using CSVFiles
import Requests: get, post, put, delete, options

using Base.Dates
using Gadfly
using Twitter
using DataFrames
using RDatasets
using CSV
using Combinatorics

twitterauth("6vY8c73zOahCzJcWf9yxoTEUl",
            "A7Y9beqYD7e6CxHpOqC3l0qB3APcFycvkQSPF8ILqgizYl0PHw",
            "4474981697-OBkMA0u5WHvChg1BVtQr5OIjgDHJN8bGwEiknQq",
            "LAZKFdUXbyZXndgLVJoUgO36ZuSyarx56CxfST84XxZ7h")

etiket="#VatanHainiBesiktas"
#### BU DEĞERLER VARSAYILAN OLARAK BOŞTUR SADECE BİRİ DOLU OLABİLİR.
KullaniciAdi=""

#Twitkatayısı 100xSayımız şeklinedir.
CekilenTwetSayisi = 10
#Analize girecek kelimelerin en az tekrar sayısı
MinimumKelimeSayısı = 2
MinKarakterSayisi = 2


#################################################################################

function TweetKullanıcı()
    #Kullanıcı Adına Göre Twet Listelemek için
    duke_tweets = get_user_timeline(;options = Dict{Any, Any}("screen_name" => KullaniciAdi,"count" => "1","tweet_mode"=>"full_text"))
    for i=1:CekilenTwetSayisi
        println(length(duke_tweets))
        append!(duke_tweets,get_user_timeline(;options = Dict{Any, Any}("max_id"=>string(duke_tweets[length(duke_tweets)].id),"screen_name" => KullaniciAdi,"count" => "100","tweet_mode"=>"full_text")))
        #Her döngüde son çekilen tiviti tekrar çektiği için son tiviti sildik ama son döngüdeki en son twiti silmedik.
        if i!=CekilenTwetSayisi
            splice!(duke_tweets,length(duke_tweets))
        end
    end
    # 1. twiti 2 kere çekttiğimiz için 1. twiti sildik.
    splice!(duke_tweets,1)
    return duke_tweets
end

function TweetHashtag()
    #Girilen Hastag'e göre arama yapıyor
    duke_tweets = get_search_tweets(etiket;options = Dict("count" => "1","tweet_mode"=>"full_text"))
    for i=1:CekilenTwetSayisi
        println(length(duke_tweets))
        append!(duke_tweets,get_search_tweets(etiket;options = Dict("max_id"=>string(duke_tweets[length(duke_tweets)].id),"count" => "100","tweet_mode"=>"full_text")))
        #Her döngüde son çekilen tiviti tekrar çektiği için son tiviti sildik ama son döngüdeki en son twiti silmedik.
        if i!=CekilenTwetSayisi
            splice!(duke_tweets,length(duke_tweets))
        end
    end
    # 1. twiti 2 kere çekttiğimiz için 1. twiti sildik.
    splice!(duke_tweets,1)
    return duke_tweets
end

function KarakterTemizleme(TemizlenecekDizi)
    dizi3=[]
    #özel karakterler silindi
    TemizlenecekDiziLength=length(TemizlenecekDizi)
    i=1;j=1
    for i=1:TemizlenecekDiziLength
        #İçerdeki for için ayrıca dizi2 nin boyutuna ihtiyacımız var.
        dizi2LengthJ=length(TemizlenecekDizi[i])
        for j=1:dizi2LengthJ
            #Dizide sadece aşağıdaki karakterlerin kalması sağlandı. Olmayanlar sadece silindi
            push!(dizi3,replace(TemizlenecekDizi[i][j],r"[^#@qwertyuıopğüasdfghjklşizxcvbnmöçQWERTYUIOPĞÜİŞLKJHGFDSAZXCVBNMÖÇ1234567890]",""))
        end
    end
    return dizi3
end

function KarakterBoyutlandırma(diziKarakterBoyutlandırma)
    diziKarakterBoyutlandırmaLength=length(diziKarakterBoyutlandırma)
    #Karakterlerin hepsi İlk harfi büyük diğer harfleri küçük hale geldi.
        for i=1:diziKarakterBoyutlandırmaLength
            #Tüm karakterleri lüçük hale getirdik
            diziKarakterBoyutlandırma[i]=lowercase(diziKarakterBoyutlandırma[i])
            #Karaketerlerin baş harfleri büyük hale getirildi
            diziKarakterBoyutlandırma[i]=titlecase(diziKarakterBoyutlandırma[i])
        end
        return diziKarakterBoyutlandırma
end

function İstenmeyenElemanSilme(dizi3)
    dizi3Length=length(dizi3)
    for i=1:dizi3Length
        dizi3Length=length(dizi3)
        if i>dizi3Length
            return dizi3
        end
            #startswith(dizi3[i],"https")==true ise sildik.https ile başlayan elemanlar siindi.
        while 1<2
            if startswith(dizi3[i],"Https")==true || dizi3[i]=="Rt" || dizi3[i]=="" || length(dizi3[i])<2 || startswith(dizi3[i],"@")==true
                splice!(dizi3,i)
                    #son elemanlardan 1 den fazla aynı varsa hepsini sildiğinde öyle bir dizi indisi kalmadığında hata vermemesi için.
                    dizi3Length=length(dizi3)
                    if i>dizi3Length
                        break
                    end
            else
                break
            end
        end
    end
end

function Apriori(TwetleriYolla,KelimeleriYolla,istenilenYüzdex)

    istenilenYüzde=istenilenYüzdex
    okunanDataFarme=TwetleriYolla
    okunanDataFarme2=KelimeleriYolla

    KelimelerinYüzdeleri=@sprintf("%.3f",(okunanDataFarme2[1,1]*100)/sum(okunanDataFarme2[1]))
    yüzdeDateFrame=DataFrame(KelimeninYüzdesi=[KelimelerinYüzdeleri],Kelimeler=okunanDataFarme2[1,2])
    deleterows!(yüzdeDateFrame,1)
    for i=1:length(okunanDataFarme2[1])
        KelimelerinYüzdeleri=@sprintf("%.3f",(okunanDataFarme2[i,1]*100)/sum(okunanDataFarme2[1]))
        if KelimelerinYüzdeleri>string(istenilenYüzde)
            append!(yüzdeDateFrame,DataFrame(KelimeninYüzdesi=[KelimelerinYüzdeleri],Kelimeler=okunanDataFarme2[i,2]))
        end
    end


    kartz=yüzdeDateFrame[2][1:length(yüzdeDateFrame[2])]

    for i=1:length(kartz)
        kartz[i]=lowercase(kartz[i])
    end

    for i=1:length(okunanDataFarme)
        okunanDataFarme[i,1]=lowercase(okunanDataFarme[i,1])
    end

    Twitlerimiz=[]
    dataLength=length(okunanDataFarme)
    for i=1:dataLength
        push!(Twitlerimiz,replace(okunanDataFarme[i,1],r"[^#@qwertyuıopğüasdfghjklşizxcvbnmöçQWERTYUIOPĞÜİŞLKJHGFDSAZXCVBNMÖÇ1234567890]"," "))
    end
    n=1


    while 1<2

        n+=1
        print(n)
        combs_of_size = collect(combinations(kartz, n))

        for i=1:length(combs_of_size)
            push!(combs_of_size,reverse(combs_of_size[i]))
        end


        AranacakKelimeler=[]
        for i=1:length(combs_of_size)
            push!(AranacakKelimeler,join(combs_of_size[i]," "))
        end


        sayac=0
        KelimeSaısıToplamı=0
        Yüzdemiz=0
        dd=DataFrame(KelimeninYüzdesi=[10],KelimeMiktarları=[1],Kelimeler=[AranacakKelimeler[1]])
        deleterows!(dd,1)

        for i=1:length(AranacakKelimeler)
            for j=1:length(Twitlerimiz)
                if searchindex(Twitlerimiz[j], AranacakKelimeler[i])>0
                    #println(i,"->>",AranacakKelimeler[i],"->>",Twitlerimiz[j])
                    sayac+=1
                end
            end
            if sayac!=0
               append!(dd,DataFrame(KelimeninYüzdesi=[Yüzdemiz],KelimeMiktarları=[sayac],Kelimeler=[AranacakKelimeler[i]]))
               KelimeSaısıToplamı+=sayac
               sayac=0
            end
        end



        frmatlıyazma=@sprintf("%.3f",(dd[1,2]*100)/length(OkunanTweetMetinleri))
        vv=DataFrame(KelimeninYüzdesi=[frmatlıyazma])
        for i=2:length(dd[1])
            frmatlıyazma=@sprintf("%.3f",(dd[i,2]*100)/length(OkunanTweetMetinleri))
            append!(vv,DataFrame(KelimeninYüzdesi=[frmatlıyazma]))
        end
        #yüzdeleri dd dataframesine attık
        dd[1]=vv[1]

        VerierinKayd(dd)

        kartz=[]
        for i=1:length(dd[1])
            if dd[i,1]>string(istenilenYüzde)
                fakedizi=[]
                append!(fakedizi,split(dd[i,3]))
                for j=1:length(fakedizi)
                    if length(find(kartz.==fakedizi[j]))==0
                        push!(kartz,fakedizi[j])
                    end
                end
            end
        end

        if  length(kartz)==0
            break
        end

    end
    return
end

function VerierinKayd(dd)
    #Zaman ekelemk için zaman parsing işlemleri
    Znow=now()
    ZamanMinute=Dates.minute(Znow) ; ZamanSecond=Dates.second(Znow) ; ZamanHour=Dates.hour(Znow) ; ZamanMilisaniye=Dates.Millisecond(Znow)
    VeriEtiketi="D:\\Karşılaştırma""+"string(today(),"","+",ZamanHour,".",ZamanMinute,"."string(ZamanMilisaniye))".csv"
    CSV.write(VeriEtiketi,dd)
    #datafraeyi pc ye kaydedicen burda
    return
end

################################################################################


if KullaniciAdi!=""
        duke_tweets=TweetKullanıcı()
end

if etiket!=""
        duke_tweets=TweetHashtag()
end

tweet_user_name=[] ; tweet_user_id=[] ; OkunanTweetMetinleri=[]
for i=1:length(duke_tweets)
    #RT olan ve 140 karakteri geçenler için
    if duke_tweets[i].text==nothing
        push!(OkunanTweetMetinleri,duke_tweets[1].retweeted_status["full_text"])
        #RT olan ve 140 karakteri geçmeyenler için
    elseif duke_tweets[i].retweeted_status!=nothing
        push!(OkunanTweetMetinleri,duke_tweets[i].retweeted_status["text"])
    else
        #rt olmayanlar için
        push!(OkunanTweetMetinleri,duke_tweets[i].text)
    end
    #bu değerler twitleri ve kullanıcı idlerini csv dosyasına yazdıran değişkenler.
    push!(tweet_user_name,duke_tweets[i].user["name"])
    push!(tweet_user_id,duke_tweets[i].user["id"])
end

dizi2=[];
for i=1:length(OkunanTweetMetinleri)
    #tek tek ayırdık dizi2ye attık ayrıdıklarımızı değerleri
    push!(dizi2,split(OkunanTweetMetinleri[i]))
end

#Diziyi temizlemek için temizleme fonksiyonuna gönderdik.
dizi3=KarakterTemizleme(dizi2)

if etiket!=""
    dizi3Length=length(dizi3)
    # "#" ifademizi diziden çıkardık
    for i=1:dizi3Length
        dizi3Length=length(dizi3)
        if i>dizi3Length
            break
        end
        if startswith(dizi3[i],etiket)==true
            splice!(dizi3,i)
        end
    end
end

#Tüm string ifadelerin baş harfi büyük diğer harfleri küçük hale getirildi.
dizi3=KarakterBoyutlandırma(dizi3)

#RT, https, @ gibi ifadelerin diziden silinmesi işlemi. --> Mutlaka dizi olmalı !é!
dizi3=İstenmeyenElemanSilme(dizi3)

dizi3Length=length(dizi3)
sayac=1
#Diziyi sıraladık
dizi3=sort(dizi3)
diziKelime=[]
diziKelimeSayisi=[]

#Tekrar sayısı 1den fazla olanarın tespiti
for i=1:dizi3Length-2
    #Elemanları karşılaştırdık. i inci eleman ve sonrası. sONRAKİ ELEMAN aynı olduğu sürece dönüyor kodumuz.
    if dizi3[i]==dizi3[i+1] && length(dizi3[1])>(MinKarakterSayisi)
        sayac+=1
        #elemalar aynı oldukça sayacımızı arttırıyoruz.
        if sayac>=MinimumKelimeSayısı
            #dizimiz i+1 ile i+2 şit olmadığında yazıyoruz ekrana sadece.
            if dizi3[i+1]!=dizi3[i+2]
                #println(dizi3[i]," = ",sayac)
                push!(diziKelime,dizi3[i])
                push!(diziKelimeSayisi,sayac)
                sayac=1
            end
        end
    end
end


#Eleman sayısı bir olanların yazırılması
#for i=1:dizi3Length-1
    #if dizi3[i]!=dizi3[i+1]
        #println(dizi3[i]," = ",1)
    #end
#end

#etiket boş ise kullanıcı adı etikete eşitlendi.
if etiket==""
    etiket=KullaniciAdi
end

#Zaman ekelemk için zaman parsing işlemleri
Znow=now() ; ZamanMinute=Dates.minute(Znow) ; ZamanSecond=Dates.second(Znow) ; ZamanHour=Dates.hour(Znow)
VeriEtiketi="D:\\"string(etiket)"+"string(today(),"","+",ZamanHour,".",ZamanMinute)".csv"

#Kullanıcının id, isim ve tweetleri bir dosyaya yazılıtyor. Dataframe içinde veriler
KullanıcıTweetBilgileriIDvsUserName=DataFrame(KullanıcıID=Array(tweet_user_id),KullanıcıEkranAdı=Array(tweet_user_name),Tweet=Array(OkunanTweetMetinleri))
CSV.write(VeriEtiketi,KullanıcıTweetBilgileriIDvsUserName)

data=DataFrame(KelimeMiktarları=Array(diziKelimeSayisi),Kelimeler=Array(diziKelime))
#alfabetik sıraya göredir.
        #dataGrafik=plot(data,x=:Kelimeler,y=:KelimeMiktarları,color=:KelimeMiktarları,Geom.bar)
        #En son çizilen grafiği Resim dosyası olarak kaydetme=
        #draw(SVG("D:\\"string(etiket)" "string(today())".svg",40cm,20cm),dataGrafik)
#kaydettik dosyaya
CSV.write(VeriEtiketi,data)

#Apriori Fonksiyonu çağırma

Apriori(OkunanTweetMetinleri,data,1)



#okuduk
    #okunanDataFarme=readtable("D:\\....csv")
#okuduk
    #okunanDataFarme2=readtable("D:\\....csv")
#okuduğumuzu çizdik
        #dataGrafik2=plot(okunanDataFarme,x=:Kelimeler,y=:KelimeMiktarları,color=:KelimeMiktarları,Geom.bar)
#En son çizilen grafiği Resim dosyası olarak kaydetme
        #draw(SVG("D:\\fff.svg",500cm,30cm),dataGrafik2)


#Aynı olan kelimelerin iki datadaki sayıları
            #    Karşılaştırma=join(okunanDataFarme, okunanDataFarme2, on=:Kelimeler)
            #    Karşılaştırmadatagrf=plot(layer(Karşılaştırma,x=:Kelimeler,y=:KelimeMiktarları,Geom.point,Theme(default_color=color("red"))),
            #    layer(Karşılaştırma,x=:Kelimeler,y=:KelimeMiktarları_1,Geom.point,Theme(default_color=color("blue"))))
            #    draw(SVG("D:\\Karş.svg",50cm,30cm),Karşılaştırmadatagrf)
            #    plot(Karşılaştırma,x=:Kelimeler,y=:KelimeMiktarları,Theme(default_color=color("red")))
