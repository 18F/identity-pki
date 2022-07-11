generate-with-header:
	trestle author ssp-generate -p gitlab -o dist/system-security-plans/gitlab -y status_header.yaml

generate:
	trestle author ssp-generate -p gitlab -o dist/system-security-plans/gitlab

assemble:
	trestle author ssp-assemble --markdown dist/system-security-plans/ --output gitlab

status:
	grep -R "\- c\-" dist/system-security-plans/* | cut -d':' -f2 | sed -E 's/^.*(c-)/\1/' | sort | uniq -c
