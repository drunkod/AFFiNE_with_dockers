import { style } from '@vanilla-extract/css';

export const paddingX = 16;
export const columnGap = 17;

export const masonry = style({
  padding: `16px ${paddingX}px`,
  columnGap: columnGap,
});
export const masonryItem = style({
  breakInside: 'avoid',
  marginBottom: 10,
});
