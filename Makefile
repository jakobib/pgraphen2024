.PHONY: html

html:
	quarto render && rm -f docs/*.ipynb
