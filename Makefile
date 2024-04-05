.PHONY: html

html:
	quarto render && rm docs/*.ipynb
