﻿
&НаКлиенте
Процедура загрузить(Команда)
	ПрочитатьExcel();
КонецПроцедуры  

&НаКлиенте
Асинх Процедура ПрочитатьExcel()
	
	ПараметрыДиалога = Новый ПараметрыДиалогаПомещенияФайлов;
	ПараметрыДиалога.Заголовок = "Выберите файл";
	ПараметрыДиалога.Фильтр = "Файл накладной | *.csv;";
	
	ОписаниеФайла = Ждать ПоместитьФайлНаСерверАсинх(,,,ПараметрыДиалога);
	Если ОписаниеФайла <> Неопределено Тогда
		ПрочитатьExcelВТаблицуЗначений(ОписаниеФайла.Адрес, ОписаниеФайла.СсылкаНаФайл.Расширение);
	КонецЕсли;
	
	ПоказатьОповещениеПользователя("Обработка файла завершена!");
	
КонецПроцедуры

&НаСервереБезКонтекста
Процедура ПрочитатьExcelВТаблицуЗначений(Знач АдресДанных,Знач РасширениеФайла)
	
	ПутьКфайлу = ПолучитьИмяВременногоФайла(РасширениеФайла);
	
	Данные = ПолучитьИзВременногоХранилища(АдресДанных);
	Данные.Записать(ПутьКфайлу);
	
	Попытка
		ТаблицаЧтения = ПрочитатьCSVвТЗ(ПутьКфайлу, Истина);
		УдалитьФайлы(ПутьКфайлу);
	Исключение
		ТекстОшибки = НСтр("ru = 'Ошибка чтения таблицы из файла excel!'");
		ЗаписьЖурналаРегистрации(ТекстОшибки, УровеньЖурналаРегистрации.Ошибка, , , ПодробноеПредставлениеОшибки(ИнформацияОбОшибке()));
		ОбщегоНазначения.СообщитьПользователю(ТекстОшибки);
		ВызватьИсключение;
	КонецПопытки;
	
КонецПроцедуры

&НаСервереБезКонтекста
Функция ТипКолонкиОтИмени(ЗаголовокКолонки)

	Если ЗаголовокКолонки = "Цена с НДС" Или ЗаголовокКолонки = "Количество" 
		Или ЗаголовокКолонки = "Сумма с НДС" Или ЗаголовокКолонки = "Сумма НДС" Тогда
		
		Возврат ОбщегоНазначения.ОписаниеТипаЧисло(15,2);
	Иначе
		Возврат ОбщегоНазначения.ОписаниеТипаСтрока(150);
	КонецЕсли;

КонецФункции // ()

&НаСервереБезКонтекста
Функция ПрочитатьCSVвТЗ(ИмяФайла,ЗаголовкиИзПервойСтроки = Ложь, Разделитель=";")
	
	Текст = Новый ЧтениеТекста(ИмяФайла);
	Результат = Новый ТаблицаЗначений;
	
	ТекСтрока = Текст.ПрочитатьСтроку();
	
	Если ТекСтрока <> Неопределено Тогда
		МассивЗначений = СтрРазделить(ТекСтрока, Разделитель);
		ИндексКолонки = 0;
		Для Каждого ИмяКолонки Из МассивЗначений Цикл
			ИмяКолонки = ?(ЗаголовкиИзПервойСтроки, ИмяКолонки, "Кол" +ИндексКолонки);
			Результат.Колонки.Добавить("Колонка" + ИндексКолонки, ТипКолонкиОтИмени(ИмяКолонки), ИмяКолонки);
			ИндексКолонки = ИндексКолонки + 1;
		КонецЦикла;
		Если ЗаголовкиИзПервойСтроки Тогда
			ТекСтрока = Текст.ПрочитатьСтроку();
		КонецЕсли;
	КонецЕсли;
	
	Пока ТекСтрока <> Неопределено Цикл 
		НоваяСтрока = Результат.Добавить();
		
		МассивЗначений = СтрРазделить(ТекСтрока, Разделитель);
		КоличествоКолонок = Мин(Результат.Колонки.Количество(), МассивЗначений.Количество());
		Для ИндексКолонки = 0 По КоличествоКолонок - 1 Цикл
			НоваяСтрока[ИндексКолонки] = МассивЗначений[ИндексКолонки];
		КонецЦикла;
		
		ТекСтрока = Текст.ПрочитатьСтроку();
	КонецЦикла;
	
	Результат = ТзЗапрос(Результат);
	
	Текст.Закрыть();
	
	Возврат Результат;
	
КонецФункции

&НаСервереБезКонтекста
Функция ТзЗапрос(ТЗ)
	
	Запрос = Новый Запрос;
	
	Запрос.Текст = 
	"ВЫБРАТЬ
	|	ТЗ.Колонка0 КАК Дата,
	|	ТЗ.Колонка1 КАК Номер,
	|	ТЗ.Колонка2 КАК Проведен,
	|	ТЗ.Колонка3 КАК ВходНомер,
	|	ТЗ.Колонка5 КАК ИннПоставщик,
	|	ТЗ.Колонка7 КАК Поставщик,
	|	ТЗ.Колонка9 КАК Сотрудник,
	|	ТЗ.Колонка11 КАК Склад,
	|	ТЗ.Колонка14 КАК Номенклатура,
	|	ТЗ.Колонка17 КАК Количество,
	|	ВЫРАЗИТЬ(ТЗ.Колонка18 КАК ЧИСЛО(15, 1)) КАК ЦенаСНдс,
	|	ВЫРАЗИТЬ(ТЗ.Колонка19 КАК ЧИСЛО(15, 1)) КАК СуммаСНДС,
	|	ВЫРАЗИТЬ(ТЗ.Колонка20 КАК ЧИСЛО(15, 1)) КАК СуммаНДС,
	|	ТЗ.Колонка21 КАК СтавкаНДС,
	|	ТЗ.Колонка30 КАК ЕдиницаИзмерения,
	|	ТЗ.Колонка41 КАК НомерТТН
	|ПОМЕСТИТЬ вт_Тз
	|ИЗ
	|	&ТЗ КАК ТЗ
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|ВЫБРАТЬ
	|	вт_Тз.Дата КАК Дата,
	|	вт_Тз.Номер КАК Номер,
	|	вт_Тз.Проведен КАК Проведен,
	|	вт_Тз.ВходНомер КАК ВходНомер,
	|	вт_Тз.ИннПоставщик КАК ИннПоставщик,
	|	вт_Тз.Поставщик КАК Поставщик,
	|	вт_Тз.Сотрудник КАК Сотрудник,
	|	вт_Тз.Склад КАК Склад,
	|	вт_Тз.Номенклатура КАК Номенклатура,
	|	СУММА(вт_Тз.Количество) КАК Количество,
	|	СУММА(вт_Тз.ЦенаСНдс) КАК ЦенаСНдс,
	|	СУММА(вт_Тз.СуммаСНДС) КАК СуммаСНДС,
	|	СУММА(вт_Тз.СуммаНДС) КАК СуммаНДС,
	|	вт_Тз.СтавкаНДС КАК СтавкаНДС,
	|	вт_Тз.ЕдиницаИзмерения КАК ЕдиницаИзмерения,
	|	вт_Тз.НомерТТН КАК НомерТТН
	|ИЗ
	|	вт_Тз КАК вт_Тз
	|
	|СГРУППИРОВАТЬ ПО
	|	вт_Тз.Номенклатура,
	|	вт_Тз.ЕдиницаИзмерения,
	|	вт_Тз.СтавкаНДС,
	|	вт_Тз.Дата,
	|	вт_Тз.Номер,
	|	вт_Тз.Проведен,
	|	вт_Тз.ВходНомер,
	|	вт_Тз.ИннПоставщик,
	|	вт_Тз.Поставщик,
	|	вт_Тз.Сотрудник,
	|	вт_Тз.Склад,
	|	вт_Тз.НомерТТН
	|ИТОГИ ПО
	|	ВходНомер";
	
	
	Запрос.УстановитьПараметр("ТЗ", ТЗ);
	
	ТаблицаНакладных = Запрос.Выполнить().Выгрузить();
	
	Возврат ТаблицаНакладных;
	
КонецФункции // ()

Процедура ТестГита()

	а = 1;
    а = 2;
	Б = 3;
	ТестКлон = "Один";
	ТестКлон = "Два";
	
	Тест4 = "";
	
	
	НовыйТест = "";
	
КонецПроцедуры

