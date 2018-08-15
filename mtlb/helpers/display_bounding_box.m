function [] = display_bounding_box(I, boxPosition, lineWidth)

figure; clf;
imshow(I);
hold on
rectangle('Position', boxPosition, 'LineWidth', lineWidth, 'EdgeColor','y');

end
