package org.badvision.outlaweditor.ui.impl;

import java.util.HashMap;
import java.util.logging.Level;
import java.util.logging.Logger;
import javafx.event.ActionEvent;
import javafx.scene.control.ListCell;
import javafx.scene.control.ListView;
import javafx.scene.control.Menu;
import javafx.scene.control.RadioMenuItem;
import javafx.scene.control.ToggleGroup;
import javafx.scene.control.cell.ComboBoxListCell;
import javafx.scene.image.Image;
import javafx.scene.image.ImageView;
import javafx.scene.image.WritableImage;
import javafx.util.Callback;
import org.badvision.outlaweditor.Application;
import static org.badvision.outlaweditor.Application.currentPlatform;
import static org.badvision.outlaweditor.Application.gameData;
import org.badvision.outlaweditor.MapEditor;
import org.badvision.outlaweditor.TransferHelper;
import static org.badvision.outlaweditor.data.PropertyHelper.bind;
import static org.badvision.outlaweditor.data.PropertyHelper.stringProp;
import org.badvision.outlaweditor.data.TileUtils;
import org.badvision.outlaweditor.data.xml.Map;
import org.badvision.outlaweditor.data.xml.Script;
import org.badvision.outlaweditor.data.xml.Tile;
import org.badvision.outlaweditor.ui.EntitySelectorCell;
import org.badvision.outlaweditor.ui.MapEditorTabController;
import org.badvision.outlaweditor.ui.ToolType;
import org.badvision.outlaweditor.ui.UIAction;
import static org.badvision.outlaweditor.ui.UIAction.confirm;
import static org.badvision.outlaweditor.ui.UIAction.createAndEditScript;

/**
 *
 * @author blurry
 */
public class MapEditorTabControllerImpl extends MapEditorTabController {
    final TransferHelper<Script> scriptDragDrop = new TransferHelper<>(Script.class);
    final TransferHelper<ToolType> toolDragDrop = new TransferHelper<>(ToolType.class);

    @Override
    public void mapEraser(ActionEvent event) {
        if (getCurrentEditor() != null) {
            getCurrentEditor().setDrawMode(MapEditor.DrawMode.Eraser);
        }
    }

    @Override
    public void mapDraw1(ActionEvent event) {
        if (getCurrentEditor() != null) {
            getCurrentEditor().setDrawMode(MapEditor.DrawMode.Pencil1px);
        }
    }

    @Override
    public void mapDraw3(ActionEvent event) {
        if (getCurrentEditor() != null) {
            getCurrentEditor().setDrawMode(MapEditor.DrawMode.Pencil3px);
        }
    }

    @Override
    public void mapDraw5(ActionEvent event) {
        if (getCurrentEditor() != null) {
            getCurrentEditor().setDrawMode(MapEditor.DrawMode.Pencil5px);
        }
    }

    @Override
    public void mapDrawFilledRectMode(ActionEvent event) {
        if (getCurrentEditor() != null) {
            getCurrentEditor().setDrawMode(MapEditor.DrawMode.FilledRect);
        }
    }

    @Override
    public void mapTogglePanZoom(ActionEvent event) {
        if (getCurrentEditor() != null) {
            getCurrentEditor().togglePanZoom();
        }
    }

    @Override
    public void mapZoomIn(ActionEvent event) {
        if (getCurrentEditor() != null) {
            getCurrentEditor().zoomIn();
        }
    }

    @Override
    public void mapZoomOut(ActionEvent event) {
        if (getCurrentEditor() != null) {
            getCurrentEditor().zoomOut();
        }
    }

    @Override
    public void onMapClonePressed(ActionEvent event) {
        throw new UnsupportedOperationException("Not supported yet."); //To change body of generated methods, choose Tools | Templates.
    }

    @Override
    public void onMapCreatePressed(ActionEvent event) {
        org.badvision.outlaweditor.data.xml.Map m = new org.badvision.outlaweditor.data.xml.Map();
        m.setName("Untitled");
        gameData.getMap().add(m);
        m.setWidth(512);
        m.setHeight(512);
        setCurrentMap(m);
        rebuildMapSelectors();
    }

    @Override
    public void onMapDeletePressed(ActionEvent event) {
        final Map currentMap = getCurrentMap();
        if (currentMap == null) {
            return;
        }
        confirm("Delete map '" + currentMap.getName() + "'.  Are you sure?", () -> {
            org.badvision.outlaweditor.data.xml.Map del = currentMap;
            setCurrentMap(null);
            Application.gameData.getMap().remove(del);
            rebuildMapSelectors();
        }, null);
    }

    @Override
    public void onMapExportPressed(ActionEvent event) {
        throw new UnsupportedOperationException("Not supported yet."); //To change body of generated methods, choose Tools | Templates.
    }

    @Override
    public void onMapPreviewPressed(ActionEvent event) {
        if (getCurrentEditor() == null) {
            return;
        }
        getCurrentEditor().showPreview();
    }

    @Override
    public void onMapScriptAddPressed(ActionEvent event) {
        createAndEditScript();
    }

    @Override
    public void onMapScriptClonePressed(ActionEvent event) {
        throw new UnsupportedOperationException("Not supported yet."); //To change body of generated methods, choose Tools | Templates.
    }

    @Override
    public void onMapScriptDeletePressed(ActionEvent event) {
        throw new UnsupportedOperationException("Not supported yet."); //To change body of generated methods, choose Tools | Templates.
    }

    @Override
    public void onMapSelected(ActionEvent event) {
        setCurrentMap(mapSelect.getSelectionModel().getSelectedItem());
    }

    @Override
    public void scrollMapDown(ActionEvent event) {
        if (getCurrentEditor() != null) {
            getCurrentEditor().scrollBy(0, 1);
        }
    }

    @Override
    public void scrollMapLeft(ActionEvent event) {
        if (getCurrentEditor() != null) {
            getCurrentEditor().scrollBy(-1, 0);
        }
    }

    @Override
    public void scrollMapRight(ActionEvent event) {
        if (getCurrentEditor() != null) {
            getCurrentEditor().scrollBy(1, 0);
        }
    }

    @Override
    public void scrollMapUp(ActionEvent event) {
        if (getCurrentEditor() != null) {
            getCurrentEditor().scrollBy(0, -1);
        }
    }

    @Override
    public Map getCurrentMap() {
        if (getCurrentEditor() == null) {
            return null;
        } else {
            return getCurrentEditor().getCurrentMap().getBackingMap();
        }
    }

    @Override
    public void completeInflightOperations() {
        if (getCurrentEditor() != null) {
            getCurrentEditor().getCurrentMap().updateBackingMap();
        }
    }

    @Override
    public void setCurrentMap(Map m) {
        if (getCurrentMap() != null && getCurrentMap().equals(m)) {
            return;
        }
        Tile currentTile = null;
//        mapEditorAnchorPane.getChildren().clear();
        if (getCurrentEditor() != null) {
            currentTile = getCurrentEditor().getCurrentTile();
            getCurrentEditor().unregister();
        }
        if (m == null) {
            bind(mapHeightField.textProperty(), null);
            bind(mapNameField.textProperty(), null);
            bind(mapWidthField.textProperty(), null);
            bind(mapWrapAround.selectedProperty(), null);
            mapHeightField.setDisable(true);
            mapNameField.setDisable(true);
            mapWidthField.setDisable(true);
            mapWrapAround.setDisable(true);
            setCurrentEditor(null);
        } else {
            sortScripts(m);
            if (m.getHeight() == null) {
                m.setHeight(512);
            }
            if (m.getWidth() == null) {
                m.setWidth(512);
            }
            if (m.getName() == null) {
                m.setName("Untitled");
            }
            try {
                mapHeightField.setDisable(false);
                mapNameField.setDisable(false);
                mapWidthField.setDisable(false);
                mapWrapAround.setDisable(false);
//                bind(mapHeightField.textProperty(), intProp(m, "height"));
                bind(mapNameField.textProperty(), stringProp(m, "name"));
//                bind(mapWidthField.textProperty(), intProp(m, "width"));
//                bind(mapWrapAround.selectedProperty(),boolProp(m, "wrap"));
            } catch (NoSuchMethodException ex) {
                Logger.getLogger(ApplicationUIControllerImpl.class.getName()).log(Level.SEVERE, null, ex);
            }
            MapEditor e = new MapEditor();
            e.setEntity(m);
            e.buildEditorUI(mapEditorAnchorPane);
            setCurrentEditor(e);
            e.setupDragDrop(scriptDragDrop, toolDragDrop);
            if (currentTile != null) {
                e.setCurrentTile(currentTile);
            }
        }
        redrawMapScripts();
    }

    @Override
    public void rebuildMapSelectors() {
        mapSelect.getItems().clear();
        mapSelect.getItems().addAll(Application.gameData.getMap());
        mapSelect.getSelectionModel().select(getCurrentMap());
    }

    @Override
    public void initalize() {
        super.initalize();
        mapSelect.setButtonCell(new ComboBoxListCell<org.badvision.outlaweditor.data.xml.Map>() {
            {
                super.setPrefWidth(125);
            }

            @Override
            public void updateItem(Map item, boolean empty) {
                textProperty().unbind();
                super.updateItem(item, empty);
                if (item != null) {
                    textProperty().bind(mapNameField.textProperty());
                } else {
                    setText(null);
                }
            }
        });
        mapSelect.setCellFactory((ListView<Map> param) -> new EntitySelectorCell<Map>(mapNameField, null) {
            @Override
            public void finishUpdate(Map item) {
            }
        });
        toolDragDrop.registerDragSupport(scriptEraseTool, ToolType.ERASER);
    }
    
    @Override
    public void rebuildTileSelectors() {
        mapSelectTile.getItems().clear();
        
        ToggleGroup tileGroup = new ToggleGroup();
        HashMap<String,Menu> submenus = new HashMap<>();
        Application.gameData.getTile().stream().forEach((Tile t) -> {
            WritableImage img = TileUtils.getImage(t, currentPlatform);
            ImageView iv = new ImageView(img);
            String category = String.valueOf(t.getCategory());
            Menu categoryMenu = submenus.get(category);
            if (categoryMenu == null) {
                categoryMenu = new Menu(category);
                submenus.put(category, categoryMenu);
            }
            final Menu theMenu = categoryMenu;
            RadioMenuItem tileSelection = new RadioMenuItem(String.valueOf(t.getName()), iv);
            tileSelection.setToggleGroup(tileGroup);
            if (getCurrentEditor() != null && getCurrentEditor().getCurrentTile() == t) {
                tileGroup.selectToggle(tileSelection);
                theMenu.setStyle("-fx-font-weight:bold; -fx-text-fill:blue");
            }
            tileSelection.setGraphic(new ImageView(TileUtils.getImage(t, currentPlatform)));
            tileSelection.setOnAction((event) -> {
                if (getCurrentEditor() != null) {
                    getCurrentEditor().setCurrentTile(t);
                }
                tileGroup.selectToggle(tileSelection);
                submenus.values().stream().forEach((menu) -> {
                    menu.setStyle(null);
                });
                theMenu.setStyle("-fx-font-weight:bold; -fx-text-fill:blue");
            });
            categoryMenu.getItems().add(tileSelection);
        });
        submenus.values().stream().forEach((menu) -> {
            mapSelectTile.getItems().add(menu);
        });
    }

    @Override
    public void redrawMapScripts() {
        mapScriptsList.setOnEditStart((ListView.EditEvent<Script> event) -> {
            UIAction.editScript(event.getSource().getItems().get(event.getIndex()));
        });
        mapScriptsList.setCellFactory(new Callback<ListView<Script>, ListCell<Script>>() {
            @Override
            public ListCell<Script> call(ListView<Script> param) {
                final ListCell<Script> cell = new ListCell<Script>() {
                    @Override
                    protected void updateItem(Script item, boolean empty) {
                        super.updateItem(item, empty);
                        if (empty || item == null) {
                            setText("");
                        } else {
                            ImageView visibleIcon = getVisibleIcon(item);
                            visibleIcon.setOnMouseClicked((e)->{
                                toggleVisibility(visibleIcon, item);
                                mapScriptsList.getSelectionModel().clearSelection();
                            });
                            setGraphic(visibleIcon);
                            getCurrentEditor().getCurrentMap().getScriptColor(item).ifPresent(this::setTextFill);
                            setText(item.getName());
                            scriptDragDrop.registerDragSupport(this, item);
                            visibleIcon.setMouseTransparent(false);
                        }
                    }
                };
                return cell;
            }
        });
        if (getCurrentMap() == null) {
            mapScriptsList.getItems().clear();
        } else {
            if (mapScriptsList.getItems() != null && getCurrentMap().getScripts() != null) {
                sortScripts(getCurrentMap());
                mapScriptsList.getItems().setAll(getCurrentMap().getScripts().getScript());
            } else {
                mapScriptsList.getItems().clear();
            }
        }
    }
    
    public static final Image VISIBLE_IMAGE = new Image("images/visible.png");
    public static final Image INVISIBLE_IMAGE = new Image("images/not_visible.png");
    
    private ImageView getVisibleIcon(Script script) {
        if (getCurrentEditor().isScriptVisible(script)) {
            return new ImageView(VISIBLE_IMAGE);
        } else {
            return new ImageView(INVISIBLE_IMAGE);
        }
    }
    
    private void toggleVisibility(ImageView visibilityIcon, Script script) {
        if (script.getName() == null) return;
        if (getCurrentEditor().isScriptVisible(script)) {
            getCurrentEditor().setScriptVisible(script, false);
            visibilityIcon.setImage(INVISIBLE_IMAGE);
        } else {
            getCurrentEditor().setScriptVisible(script, true);
            visibilityIcon.setImage(VISIBLE_IMAGE);
        }
    }

    private void sortScripts(Map m) {
        m.getScripts().getScript().sort((a,b)-> {
            if (a.getName().equalsIgnoreCase("init")) {
                return -1;
            } else if (b.getName().equalsIgnoreCase("init")) {
                return 1;
            }
            return a.getName().compareTo(b.getName());
        });
    }
}
