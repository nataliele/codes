
# Purpose: scrape datacamp websites for slides and codes for reference
# Source: http://stanford.edu/~mgorkove/cgi-bin/rpython_tutorials/Scraping_a_Webpage_Rendered_by_Javascript_Using_Python.php
#         http://selenium-python.readthedocs.io/navigating.html
# Packages: selenium, requests


from selenium import webdriver
import requests
import os

# get working directory to save files
working_dir = os.getcwd()

# use special browser that Python can control
driver = webdriver.Chrome() #replace with .Firefox(), or with the browser of your choice

# open website to log in
# url_module = 'https://www.datacamp.com/tracks/data-scientist-with-python'
url_login = 'https://www.datacamp.com/users/sign_in'
driver.get(url_login)

# log in
username = driver.find_element_by_id("user_email") #username form field
password = driver.find_element_by_id("user_password") #password form field

username.send_keys("yourmail@somemail.com")
password.send_keys("password")

submitButton = driver.find_element_by_name("commit")
submitButton.click()


# get list of modules in Data Science track
modules = driver.find_elements_by_class_name('dc-activity-block__stat-dropdown-link')

# extract links from web elements
module_list = [i.get_attribute('href') for i in modules]
# Remove empty modules
module_list = [module for module in module_list if module!=None]

# len(module_list)
# 24

# loop to go through each module
for module in module_list:
    # create folder for text files and pdfs
    module_name = module.split(sep='/')[-1]  # get name of the module by spliting the http link and get the last string
    new_dir = os.path.join(working_dir, module_name)
    if not os.path.exists(new_dir):
        os.makedirs(new_dir)

    # go to the module's website and find all classes/lessons
    driver.get(module)
    # find all classes/lessons
    lessons = driver.find_elements_by_class_name('chapter__exercise-link')
    lesson_list = [i.get_attribute('href') for i in lessons]
    # lesson_name_list = []

    # loop to go through each class/lesson page until all texts and pdf files are found
    for lesson in lesson_list:
        try:
            # url = classes_list[i]
            driver.get(lesson)  # navigate to the page

            # find all lesson texts
            lesson_text = driver.find_element_by_id('rendered-view').text
            # only get the visible code, need to scroll or change window size to get all codes
            # code = driver.find_element_by_xpath('//*[@id="ace-code-editor-6"]').text

            # get lesson name by splitting into a list using '/' then choose the last item
            lesson_name = lesson.split(sep='/')[-1]
            lesson_name = lesson_name.replace('?', '_') + '.txt'
            # lesson_name_list.append(lesson_name)


            # save text to file .txt
            text_link = os.path.join(working_dir, module_name, lesson_name)
            if not os.path.isfile(text_link):
                with open(text_link, 'w') as f:
                    f.write(lesson_text)


            # find pdf files in the lesson page
            pdf = driver.find_element_by_xpath('//*[@id="gl-consoleTabs-slides"]/div/div/object').get_attribute('data')
            pdf_name = pdf.split(sep='/')[-1]
            pdf_link = os.path.join(working_dir, module_name, pdf_name)
            if not os.path.exists(pdf_link):
                # download pdf files
                r = requests.get(pdf)
                with open(pdf_link, 'wb') as f:
                    f.write(r.content)

        # video pages wont have the elements we're looking for so continue to the next item; multiple-choice pages also dont have pdf link
        except:
            continue