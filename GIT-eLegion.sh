#!/usr/bin/env bash

cd "$(dirname "${BASH_SOURCE[0]}")"

for dir in *_data; do
	if [ ! -e "${dir}" ]; then
		continue;
	fi

	filename="${dir%_data}.sketch"
	chflags hidden "$dir"
	cd "$dir"
	zip -r ../"$filename" *
	cd -
done

git init

for file in *.sh; do
	chflags hidden "$file"
done

cat <<SCRIPT > .git/hooks/pre-commit
#!/usr/bin/env bash
#Переводим все .sketch в .zip
for file in *.sketch; do
	git reset "\$file"
	git update-index --assume-unchanged "\$file"
	#Создаем директорию для распакованных файлов
	dir="\${file%.sketch}"_data
	mkdir -p "\$dir"
	rm -rf "\$dir"/*
	#Скрывем директорию
	chflags hidden "\$dir"
	#Распаковываем архив в директорию
	unzip "\$file" -d "\$dir"
	git add --all "\$dir"
done
SCRIPT

chmod u+x .git/hooks/pre-commit

cat <<SCRIPT >> .git/hooks/post-merge
#!/usr/bin/env bash
for dir in *_data; do
	filename="\${dir%_data}.sketch"
	rm "\$filename"
	cd "\$dir"
	zip -r ../"\$filename" *
	cd -
done
SCRIPT

chmod u+x .git/hooks/post-merge

cat <<SCRIPT >> .git/hooks/post-checkout
#!/usr/bin/env bash
for dir in *_data; do
	filename="${dir%_data}.sketch"
	rm "$filename"
	cd "$dir"
	zip -r ../"$filename" *
	cd -
done
SCRIPT

chmod u+x .git/hooks/post-checkout
