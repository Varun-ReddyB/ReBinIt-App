// This file will be included in index.html
let wasteModel;

async function loadWasteModel() {
  if (!wasteModel) {
    wasteModel = await tf.loadLayersModel("assets/model/web_model/model.json");
  }
  return true;
}

async function classifyWaste(imageData) {
  if (!wasteModel) return "Model not loaded";

  // imageData is a base64 string
  const img = new Image();
  img.src = imageData;
  await new Promise((r) => (img.onload = r));

  const tensor = tf.browser
    .fromPixels(img)
    .resizeNearestNeighbor([224, 224])
    .toFloat()
    .div(tf.scalar(255.0))
    .expandDims(0);

  const prediction = wasteModel.predict(tensor);
  const data = await prediction.data();
  const maxIndex = data.indexOf(Math.max(...data));
  return maxIndex.toString();
}
