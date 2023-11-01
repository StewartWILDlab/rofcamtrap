#############################################################

import matplotlib.pyplot as plt
import pandas as pd
from PIL import Image
from tqdm import tqdm
from sklearn.model_selection import train_test_split

import torch
from torch.utils.data import Dataset
from torchvision import transforms

from torch.utils.data import DataLoader

from torch import nn
import torchvision.models as models

import os

# from metaformer.models.MetaFG import * 
# from metaformer.models.MetaFG_meta import *

do_train = True
do_predict = True
replace_path = True
# path_replacement = "/workspace/project/data/images/"
path_replacement = "/home/vlucet/Documents/WILDLab/all/"
batch_size = 32
epochs = 100
random_state = 777
fit_split = 0.25
eval_split = 0.25 

print(torch.cuda.is_available())
device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
# device = "cpu"
print(device)

#############################################################

dat = pd.read_csv("3_Classifiers/1_species_classifier/labels.csv", index_col = "id")
limit = 3
dat_info = dat.iloc[:, :limit]
dat_labels = dat.iloc[:, limit:]

print(dat.head())
print(dat_info.head())

all_x = dat_info.iloc[:,0:1]
all_y = dat_labels

print(list(all_x.columns))
print(list(all_y.columns))

species_labels = (all_y.columns.unique().tolist())
print(species_labels)
number_of_categories = len(species_labels)

# print(all_y.sum().divide(all_y.shape[0]).sort_values(ascending=False))

# x_fit, x_predict, y_fit, y_predict = train_test_split(
#     all_x, all_y, stratify=all_y, test_size=fit_split, random_state=random_state
# )
# print(x_fit.shape, x_predict.shape, y_fit.shape, y_predict.shape)

# x_train, x_eval, y_train, y_eval = train_test_split(
#     x_fit, y_fit, stratify=y_fit, test_size=eval_split, random_state=random_state
# )
# print(x_train.shape, y_train.shape, x_eval.shape, y_eval.shape)

# split_pcts_fit = pd.DataFrame(
#     {
#         "fit": y_fit.idxmax(axis=1).value_counts(normalize=True),
#         "predict": y_predict.idxmax(axis=1).value_counts(normalize=True),
#     }
# )
# print("Species percentages by split")
# print((split_pcts_fit.fillna(0) * 100).astype(int))

x_train, x_eval, y_train, y_eval = train_test_split(
    all_x, all_y, stratify=all_y, test_size=eval_split, random_state=random_state
)
print(x_train.shape, y_train.shape, x_eval.shape, y_eval.shape)

split_pcts_train = pd.DataFrame(
    {
        "train": y_train.idxmax(axis=1).value_counts(normalize=True),
        "eval": y_eval.idxmax(axis=1).value_counts(normalize=True),
    }
)
# print("Species percentages by split")
# print((split_pcts_train.fillna(0) * 100).astype(int))

#############################################################

class ImagesDataset(Dataset):
    """Reads in an image, transforms pixel values, and serves
    a dictionary containing the image id, image tensors, and label.
    """

    def __init__(self, x_df, y_df=None, device="cpu"):
        self.data = x_df
        self.label = y_df
        self.transform = transforms.Compose(
            [
                transforms.Resize((224, 224)),
                # transforms.Resize((384, 384)),
                transforms.ToTensor(),
                transforms.Normalize(
                    mean=(0.485, 0.456, 0.406), std=(0.229, 0.224, 0.225)
                ),
            ]
        )
        self.device = device

    def __getitem__(self, index):
        image_path = self.data.iloc[index]["filepath"]
        if replace_path:
          image_path = path_replacement + os.path.basename(image_path)
        image = Image.open(image_path).convert("RGB")
        image = self.transform(image).to(self.device)
        image_id = self.data.index[index]
        # if we don't have labels (e.g. for test set) just return the image and image id
        if self.label is None:
            sample = {"image_id": image_id, "image": image}
        else:
            label = torch.tensor(
                self.label.iloc[index].values, dtype=torch.float
            ).to(self.device)
            sample = {"image_id": image_id, "image": image, "label": label}
        return sample

    def __len__(self):
        return len(self.data)

#############################################################

train_dataset = ImagesDataset(x_train, y_train, device=device)
train_dataloader = DataLoader(train_dataset, batch_size=batch_size)

#############################################################

model = models.resnet50()
state_dict = torch.load("models/resnet/pretrained/resnet50-11ad3fa6.pth")
model.load_state_dict(state_dict)
for param in model.parameters():
    param.requires_grad = True
# print(model)
model.fc = nn.Sequential(
    nn.Linear(2048, 100),  # dense layer takes a 2048-dim input and outputs 100-dim
    nn.ReLU(inplace=True),  # ReLU activation introduces non-linearity
    nn.Dropout(0.1),  # common technique to mitigate overfitting
    nn.Linear(
        100, number_of_categories
    ),  # final dense layer outputs 8-dim corresponding to our target classes
)
for param in model.fc.parameters():
    param.requires_grad = True
print(model)

# model = MetaFG_0(img_size=224)
# state_dict = torch.load("metaformer_models/metafg_0_1k_224.pth")
# model.load_state_dict(state_dict)
# for param in model.parameters():
#     param.requires_grad = False
# # print(model)
# model.head = nn.Sequential(
#     # nn.Linear(768, 100),  # dense layer takes a 2048-dim input and outputs 100-dim
#     # nn.ReLU(inplace=True),  # ReLU activation introduces non-linearity
#     # nn.Dropout(0.1),  # common technique to mitigate overfitting
#     nn.Linear(
#         768, number_of_categories
#     ),  # final dense layer outputs dims corresponding to our target classes
# )
# for param in model.head.parameters():
#     param.requires_grad = True
# print(model)

# from InternImage.classification.models import build
# model = build.InternImage(
#     channels=64, 
#     depths= [4, 4, 18, 4], 
#     groups=[4, 8, 16, 32])
# state_dict = torch.load("intern_models/internimage_s_1k_224.pth")
# model.load_state_dict(state_dict["model"])
# for param in model.parameters():
#     param.requires_grad = False
# print(model)
# model.head = nn.Sequential(
#     # nn.Linear(768, 100),  # dense layer takes a 2048-dim input and outputs 100-dim
#     # nn.ReLU(inplace=True),  # ReLU activation introduces non-linearity
#     # nn.Dropout(0.1),  # common technique to mitigate overfitting
#     nn.Linear(
#         768, number_of_categories
#     ),  # final dense layer outputs dims corresponding to our target classes
# )
# for param in model.head.parameters():
#     param.requires_grad = True
# # print(model)

model = model.to(device)

#############################################################

import torch.optim as optim

criterion = nn.CrossEntropyLoss()
optimizer = optim.SGD(model.parameters(), lr=0.001, momentum=0.9)

#############################################################

if do_train: 

    num_epochs = epochs

    tracking_loss = {}

    for epoch in range(1, num_epochs + 1):
        print(f"Starting epoch {epoch}")

        # iterate through the dataloader batches. tqdm keeps track of progress.
        for batch_n, batch in tqdm(
            enumerate(train_dataloader), total=len(train_dataloader)
        ):

            # 1) zero out the parameter gradients so that gradients from previous batches are not used in this step
            optimizer.zero_grad()

            # 2) run the foward step on this batch of images
            outputs = model(batch["image"]) # ;print(outputs.shape)

            # 3) compute the loss
            loss = criterion(outputs, batch["label"])
            # let's keep track of the loss by epoch and batch
            tracking_loss[(epoch, batch_n)] = float(loss)

            # 4) compute our gradients
            loss.backward()
            # update our weights
            optimizer.step()

    tracking_loss = pd.Series(tracking_loss)

    plt.figure(figsize=(10, 5))
    tracking_loss.plot(alpha=0.2, label="loss")
    tracking_loss.rolling(center=True, min_periods=1, window=10).mean().plot(
        label="loss (moving avg)"
    )
    plt.xlabel("(Epoch, Batch)")
    plt.ylabel("Loss")
    plt.legend(loc=0)
    # plt.show()
    plt.savefig('3_Classifiers/1_species_classifier/loss.png')

    print("TRAINING DONE")

    torch.save(model, "3_Classifiers/1_species_classifier/model.pth")

    print("MODEL SAVED")

#############################################################

loaded_model = torch.load("3_Classifiers/1_species_classifier/model.pth")

eval_dataset = ImagesDataset(x_eval, y_eval, device=device)
eval_dataloader = DataLoader(eval_dataset, batch_size=batch_size)

#############################################################

# put the model in eval mode so we don't update any parameters
model = model.eval()

if do_predict:

    preds_collector = []

    # we aren't updating our weights so no need to calculate gradients
    with torch.no_grad():
        for batch in tqdm(eval_dataloader, total=len(eval_dataloader)):
            # 1) run the forward step
            logits = model.forward(batch["image"])
            # 2) apply softmax so that model outputs are in range [0,1]
            preds = nn.functional.softmax(logits, dim=1)

            # print(preds.detach().numpy())
            # print(batch["image_id"])
            # print(species_labels)

            # 3) store this batch's predictions in df
            # note that PyTorch Tensors need to first be detached from their computational graph before converting to numpy arrays
            preds_df = pd.DataFrame(
                preds.detach().cpu().numpy(),
                index=batch["image_id"].numpy(),
                columns=species_labels
            )
            preds_collector.append(preds_df)

    eval_preds_df = pd.concat(preds_collector)

    eval_preds_df.to_csv("3_Classifiers/1_species_classifier/predictions.csv")

# eval_preds_df = pd.read_csv("predictions.csv", index_col=0)

print(eval_preds_df.head())

# print("True labels (training):")
# print(y_train.idxmax(axis=1).value_counts())

eval_predictions = eval_preds_df.idxmax(axis=1)
print(eval_predictions.head())

print("Predicted vs true labels (eval):")
pred_vs_eval = eval_predictions.value_counts().to_frame().rename(
    columns = {'count': 'predicted'}).merge(y_eval.idxmax(axis=1).value_counts().to_frame().rename(
        columns = {'count': 'real'}), left_index=True, right_index=True)
print(pred_vs_eval)

eval_true = y_eval.idxmax(axis=1)
print(eval_true)
(eval_true == "Goose").sum() / len(eval_predictions)
correct = (eval_predictions == eval_true).sum()
accuracy = correct / len(eval_predictions)
print(accuracy)

# from sklearn.metrics import ConfusionMatrixDisplay

# fig, ax = plt.subplots(figsize=(10, 10))
# cm = ConfusionMatrixDisplay.from_predictions(
#     y_eval.idxmax(axis=1),
#     eval_preds_df.idxmax(axis=1),
#     ax=ax,
#     xticks_rotation=90,
#     colorbar=True,
# )

# fig.savefig('cm.png')
