import turicreate as tc


# data = tc.image_analysis.load_images('Dataset', with_path=True)

# data['label'] = data['path'].apply(lambda path: 'cat' if '/CatExamples' in path else 'notcat')
# data.save('cat-notcat.sframe')
# data.show()



# data =  tc.SFrame('cat-notcat.sframe')
# train_data, test_data = data.random_split(0.8)

# model = tc.image_classifier.create(train_data, target='label')

# predictions = model.predict(test_data)

# metrics = model.evaluate(test_data)
# print(metrics['accuracy'])

# model.save('CatDetector.model')

# model.export_coreml('CMLCatDetector.mlmodel')
